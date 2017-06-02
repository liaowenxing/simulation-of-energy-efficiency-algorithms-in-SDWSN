clc;
clear;
%规定节点1为sink节点
N=150;      %节点数量
R=150;      %有效通信半径
D=800;      %场景大小
global E0;    %节点初始能量
E0=5;      %节点初始能量
K=7;       %能量等级
T=100;      %发包的周期
simutime=100000;        %仿真时间
Mode=2;     %表示网络模式，0表示WRP，1表示MES，2表示E-TORA，3表示Energy Awared，4表示LEACH_C

%Leach相关参数
Round=50;%leach_c的一轮时间
Pac=10;%每10个数据包进行融合一次

State_change=0;%表示有节点能量耗尽

%统计量
R_E=zeros(floor(simutime/1000),2);%总能量消耗
R_T=0;                      %统计能量的时刻
death_node=zeros(N,1);      %统计死亡节点
isolate_node=zeros(N,1);    %统计孤立节点

global Node;    %节点属性
global A;    %连通矩阵
global P;    %节点位置

%%%初始化节点位置和连通矩阵，为了统一仿真场景，节点分布采用同一分布
%[A,P]=init(N,R,D);
[A]=xlsread('A',1);
[P]=xlsread('P',1);
%%%初始化节点位置和连通矩阵，为了统一仿真场景，节点分布采用同一分布

%%%初始化节点信息
Node=zeros(11,N); %1表示节点到sink节点的路径，2表示节点的sink节点的距离，3表示节点发送数据包的时刻，4表示节点缓存空间的包数量，
%5表示节点的剩余能量，6表示节点能量等级，7表示节点能量空间，8表示节点是否为簇头（1为簇头，0为普通节点），9表示聚合包的个数,10表示节点的高度
%11表示节点的距离段，分别为1，2，3

%初始化包的发送时刻和能量相关信息
for i=1:1:N
    Node(3,i)=ceil(T*rand(1));
    Node(5,i)=E0;
    Node(6,i)=K;
    Node(7,i)=K;
end

if Mode==2 %E-TORA 协议
    for i=1:1:N
        Node(10,i)=Distance(1,i)/(D/2*sqrt(2));
    end
end

if Mode==4
    for i=2:1:N
        if Distance(1,i)<150
            Node(11,i)=1;
        elseif Distance(1,i)>300
            Node(11,i)=3;
        else
            Node(11,i)=2;
        end
    end
end


%初始化路由和节点与sink距离，如果是分簇的路由则在路由过程中完成分簇的算法
Routing(Mode);
%%%初始化节点信息


%%%开始发包
for t=1:1:simutime
    
    %%判断是否有包要发送
    for i=2:1:N
        if Node(5,i)>0        %节点剩余能量不为0，且节点有路由到sink节点
            
            if Node(3,i)==mod(t,T)+1        %节点有包产生
                Node(4,i)=Node(4,i)+1;
            end
            
            if Node(8,i)==1&&Node(4,i)>Pac %数据融合
                Node(4,i)=Node(4,i)-Pac;
                Node(9,i)=Node(9,i)+1;
            end
                
            %%开始发送
            if (Node(4,i)>0&&Node(8,i)~=1&&Node(1,i)~=0)||(Node(9,i)>0&&Node(8,i)==1&&Node(1,i)~=0)
                Dead_node=LeachSend(i,Node(1,i));
                
                %某次有节点能量耗尽就表示本次发送完成后需要在寻路
                if Dead_node 
                    State_change=1;
                    
                    %有节点能量耗尽，开始统计死亡节点和孤立节点,需要路由之后才能够统计孤立节点，这里暂时不考虑孤立节点的统计
                    death_node(N)=0;
                    isolate_node(N)=0;        
                    for j=2:1:N
                        if Node(1,j)==0
                            isolate_node(N)=isolate_node(N)+1;
                        end
                        if Node(5,j)<=0
                            death_node(N)=death_node(N)+1;
                        end            
                    end
                    isolate_node(isolate_node(N)+1)=t;
                    death_node(death_node(N)+1)=t; %统计n时刻死亡节点的数量 
                    %统计死亡节点和孤立节点
                    
                    %修改连接矩阵
                    switch Dead_node
                        case 1      %发送节点能量耗尽
                            A(:,i)=A(:,i)*0;
                            A(i,:)=A(i,:)*0;
                            A(i,i)=1;      
                        case 2      %接收节点能量耗尽
                            A(:,Node(1,i))=A(:,Node(1,i))*0;
                            A(Node(1,i),:)=A(Node(1,i),:)*0;
                            A(Node(1,i),Node(1,i))=1;
                        case 3      %发送和接收节点能量耗尽
                            A(:,i)=A(:,i)*0;
                            A(i,:)=A(i,:)*0;
                            A(i,i)=1;
                            A(:,Node(1,i))=A(:,Node(1,i))*0;
                            A(Node(1,i),:)=A(Node(1,i),:)*0;
                            A(Node(1,i),Node(1,i))=1;
                    end
                    %修改连接矩阵
                end 
                
                %如果是能量等级的路由，需要判断能级变化
                if Mode==1                    
                    %判断接收节点的能级变化
                    if Node(1,i)~=1
                        Node(6,Node(1,i))=ceil(K*Node(5,Node(1,i))/E0);
                        if Node(6,Node(1,i))<Node(7,Node(1,i))
                            State_change=1;
                            Node(7,Node(1,i))=Node(6,Node(1,i));
                        end
                    end
                    %判断发送节点的能级变化
                    Node(6,i)=ceil(K*Node(5,i)/E0);
                    if Node(6,i)<Node(7,i)
                        State_change=1;
                        Node(7,i)=Node(6,i);
                    end                    
                end
                %如果是能量等级的路由，需要判断能级变化
                
            end            
            %%完成发送
        end
    end    

    if Mode==3&&mod(t,2000)==0
        State_change=1;
    end
    
    if Mode==4&&mod(t,Round)==0
        State_change=1;
    end   
    
    if State_change==1;
        State_change=0;
        Routing(Mode); 
    end

    %统计总能量消耗
    if mod(t,1000)==0
        R_T=R_T+1;
        R_E(R_T,1)=t;
        R_E(R_T,2)=(N-1)*E0-sum(Node(5,2:N));
    end
        %获取t=20000时刻的节点信息
    if t==20000
        Node2=Node;
    end

end

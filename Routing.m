function Routing(Mode)
global Node;
global A;
global E0;
N=length(A);
switch Mode
    case 0 %最短路径优先
        for i=2:1:N
            path=Dijkstra(A,1,i);
            Node(1,i)=path(2);
            if path(2)~=0
                Node(2,i)=Distance(path(2),i);
            end
        end
    case 1 %能量空间MES
        for i=2:1:N
            found=0;
            if Node(7,i)==0 %节点能量耗尽不需要在寻路
                Node(1,i)=0;
                continue;
            end
            for k=Node(7,1):-1:1 %依次将最高能量空间的节点添加到子网中并计算路由
                As=A;
                for j=2:1:N %找到所有的k能量空间一下的节点，并将其ISL置为无效，得到当前的As
                    if Node(7,j)<k&&j~=i
                        As(:,j)=As(:,j)*0;
                        As(j,:)=As(j,:)*0;
                        As(j,j)=1;
                    end
                end
                path=Dijkstra(As,1,i);
                if path(2)~=0
                    Node(1,i)=path(2);
                    Node(2,i)=Distance(path(2),i);
                    found=1;
                    if k<Node(7,i)
                        Node(7,i)=k;
                    end
                    break;
                end
            end
            if found==0 %孤立节点
                Node(7,i)=0;
                Node(1,i)=0;
            end
        end                
    case 2 %E-TORA
        for i=2:1:N
            if Node(5,i)<=0 %节点能量耗尽
                Node(1,i)=0;
                continue;
            end
            temp=Node(10,i);
            found=0;
            for j=1:1:N
                if Distance(i,j)<150&&Node(10,j)<temp&&i~=j&&Node(5,j)>0%节点之间距离小于半径150,且具有更小的高度
                    temp=Node(10,j);
                    Node(1,i)=j;
                    Node(2,i)=Distance(i,j);
                    found=1;%表示找到了路由
                end
            end
            if found==0
                Node(1,i)=0;
            end
        end
     case 3 %能量感知
%          Ac=A;
%          E0=5;
%          for i=2:1:N
%              for j=1:1:N
%                  if Ac(i,j)>=1
%                      Ac(i,j)=Ac(i,j)+1-Node(5,i)/E0;
%                  end
%              end
%          end
%          for i=2:1:N
%             path=Dijkstra(Ac,1,i);
%             Node(1,i)=path(2);
%             if path(2)~=0
%                 Node(2,i)=Distance(path(2),i);
%             end
%          end            
         Ac=A;
         for i=2:1:N
             if Node(5,i)/E0<0.5
                 Ac(:,i)=Ac(:,i)*0;
                 Ac(i,:)=Ac(i,:)*0;
                 Ac(i,i)=1;
             end
         end
         for i=2:1:N
            path=Dijkstra(Ac,1,i);
            Node(1,i)=path(2);
            if path(2)==0
                path=Dijkstra(A,1,i);
                Node(1,i)=path(2);
                if path(2)~=0
                    Node(2,i)=Distance(path(2),i);
                end
            else
                Node(2,i)=Distance(path(2),i);
            end
         end
        
        
end



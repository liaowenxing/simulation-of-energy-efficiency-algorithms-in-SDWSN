function [State]=LeachSend(Src,Dest)
%损耗模型
d0=87;
Eelec=50*10^(-9);
Efs=10*10^(-12);
Emp=0.0013*10^(-12);
bit=5000;
%损耗模型
global Node;

State=0;
if Node(9,Src)==0    
    if Node(2,Src)<d0
        Node(5,Src)=Node(5,Src)-bit*Eelec-bit*Efs*Node(2,Src)^2;
    else
        Node(5,Src)=Node(5,Src)-bit*Eelec-bit*Emp*Node(2,Src)^4;
    end
    Node(5,Dest)=Node(5,Dest)-bit*Eelec;
    Node(4,Src)=Node(4,Src)-1;
    Node(4,Dest)=Node(4,Dest)+1;
else
    if Node(2,Src)<d0
        Node(5,Src)=Node(5,Src)-bit*Eelec-bit*Efs*Node(2,Src)^2;
    else
        Node(5,Src)=Node(5,Src)-bit*Eelec-bit*Emp*Node(2,Src)^4;
    end
    Node(5,Dest)=Node(5,Dest)-bit*Eelec;
    Node(9,Src)=Node(9,Src)-1;
    Node(9,Dest)=Node(9,Dest)+1;
end

if Node(5,Src)<=0
    State=1;
end

if Node(5,Dest)<=0&&Dest~=1
    State=2;
end

if Node(5,Src)<=0&&Node(5,Dest)<=0&&Dest~=1
    State=3;
end
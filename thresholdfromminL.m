function [BW, threshold]=  thresholdfromminL(inim,ploting)



I2 = rgb2lab(inim);
l=I2(:,:,1);
a=I2(:,:,2);
b=I2(:,:,3);
if ploting ==1
    figure;
    subplot(2,2,1);imshow(inim,[]);
    subplot(2,2,2);imshow(l,[]);
    subplot(2,2,3);imshow(a,[]);
    subplot(2,2,4);imshow(b,[]);
    figure;
    subplot(1,2,1);imshow(inim,[]);
    subplot(1,2,2);imshow(l,[]);
end
lvalues=l(:);
%    level = mode(l(:))
% thresh = multithresh(l,1)
% BW = imbinarize(l,thresh);

channelmax=max(lvalues(:));

[N,edges] = histcounts(l,300, 'Normalization','probability');
edges = edges(2:end) - (edges(2)-edges(1))/2;

yy = smooth(N);
if ploting ==1
    figure;
    subplot(1,2,1);histogram(l);
    subplot(1,2,2);ploting(edges, yy);
end
x = edges;
A = yy;
[TF,~] = islocalmin(A);
% figure;plot(x,A,x(TF),A(TF),'r*')

valleys=x(TF);

u80=find(valleys>80);
b90=find(valleys<90);
tt=intersect(u80,b90);

if isempty(tt)
    threshold=86;
else
    threshold=valleys(tt(1));
end
BW = ones(size(l));
BW(l>threshold)=0;
if ploting ==1
    figure;
    subplot(1,2,1);imshow(inim,[]);
    subplot(1,2,2);imshow(BW,[]);
end
end
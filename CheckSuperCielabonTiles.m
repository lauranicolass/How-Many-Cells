clear;clc;close all

%% This code allows you to check the SuperCielab approach on individual tiles
filename=' ';
im=imread(filename);

%% mask of the image:


im_lab = rgb2lab(im);
   
   % Get the L channel
   L0 = im_lab(:,:,1);
   L0_values =L0(:);
   L0_values(L0_values == 0) = [];

   median_L0 = median(L0_values);
   P75= prctile(L0_values,75);

new_mask=zeros(size(L0));
% Calculate the superpixels
[labels, numlabels] = superpixels(im, 1000);
figure
BW = boundarymask(labels);
imshow(imoverlay(im,BW,'cyan'),'InitialMagnification',67)

% Initialize a structure to store the superpixels
superpixels = struct;

% Loop over the superpixels
for i = 1:numlabels
   % Get the mask for the current superpixel
   mask = labels == i;
   segmented = bsxfun(@times, im, cast(mask, 'like', im));
   % Store the mask in the structure
   superpixels(i).label=i;
   superpixels(i).segmented = segmented;
   superpixels(i).Mask = mask;
   
   % Convert the image to CIELAB color space
   img_lab = rgb2lab(segmented);
   
   % Get the L channel
   L = img_lab(:,:,1);
   L_values =L(:);
 
   % Remove the zero elements from the L_values array
   L_values(L_values == 0) = [];
   
   % Calculate the median L value for the current superpixel
   median_L = median(L_values);

   if median_L<P75
       decision=1;
       new_mask(labels==i)=1;
   else
       decision=0;
       new_mask(labels==i)=0;
   end
   
   % Store the median L value in the structure
   superpixels(i).Median_L = median_L;
   superpixels(i).decision = decision;
end

finalsegmentation=bsxfun(@times, im, cast(new_mask, 'like', im));

figure;imshowpair(im,finalsegmentation);


im_lab2 = rgb2lab(finalsegmentation);
   
   % Get the L channel
   L2 = im_lab2(:,:,1);
   L2_values =L2(:);
   L2_values(L2_values == 0) = [];

   median_L2 = median(L2_values);
   P702= prctile(L2_values,70);

   new_mask2=zeros(size(L2));

   new_mask2(L2<P702)=1;
   new_mask2(L2==0)=0;
   new_mask2=logical(new_mask2);
   %% remove clearly not cells:
   new_mask2 = bwpropfilt(new_mask2,'Eccentricity',[0, 0.98]);
   new_mask2 = bwpropfilt(new_mask2,'Area',[50, 2822500000]);

   %% fill very tiny holes=
   new_mask2 = ~bwareaopen(~new_mask2, 150);

   finalsegmentation2=bsxfun(@times, im, cast(new_mask2, 'like', im));


   figure;imshowpair(im,finalsegmentation2);
   figure
montage({im,finalsegmentation2})

%% try to separate objects a bit:

BW2 = bwmorph(new_mask2,'tophat');
figure;imshowpair(new_mask2,new_mask2-BW2);
figure;montage({new_mask2,new_mask2-BW2})
finalmask=logical(new_mask2-BW2);
finalsegmentation3=bsxfun(@times, im, cast(finalmask, 'like', im));
figure;imshow(finalsegmentation3);

%%

CC=bwconncomp(finalmask);
stats = regionprops(CC);
Area = [stats.Area].';

stats(Area<150)=[];

for i=1:length(stats)

numcells=floor(stats(i).Area/350);

% when an area is very big, we count more cells than supposed to: 
if numcells>10
howmany10=floor(numcells/10);
numcells=numcells-2*howmany10;
elseif numcells>5
howmany5=floor(numcells/5);
numcells=numcells-howmany5;
end
stats(i).numcells=numcells;
end

cells_in_tile=sum([stats.numcells].')

figure;imshow(finalsegmentation3)
hold on
for k = 1 
     BB = stats(k).BoundingBox;
     rectangle('Position', [BB(1),BB(2),BB(3),BB(4)],'EdgeColor','r','LineWidth',2) ;
end


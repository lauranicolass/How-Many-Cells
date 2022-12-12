function [new_mask2]=AdptThresholdSuperCielab(im)
%% This function generates superpixels over an image. Each superpixel's median L value is then compared to the median L value of the image. It only counts as "cell-tissue" if the median L of the superpixel is below the 75 percentile of the L distribution of the whole image

%% Ldistribution of image:
im_lab = rgb2lab(im);

% Get the L channel
L0 = im_lab(:,:,1);
L0_values =L0(:);
L0_values(L0_values == 0) = [];


P75= prctile(L0_values,75);

new_mask=zeros(size(L0));
% Calculate the superpixels

[labels, numlabels] = superpixels(im, 1000);


% Initialize a structure to store the superpixels
thesuperpixels = struct;

% Loop over the superpixels
for i = 1:numlabels
    % Get the mask for the current superpixel
    mask = labels == i;
    segmented = bsxfun(@times, im, cast(mask, 'like', im));
    % Store the mask in the structure
    thesuperpixels(i).label=i;
    thesuperpixels(i).segmented = segmented;
    thesuperpixels(i).Mask = mask;

    % Convert the superpixel to CIELAB color space
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
    thesuperpixels(i).Median_L = median_L;
    thesuperpixels(i).decision = decision;
end

finalsegmentation=bsxfun(@times, im, cast(new_mask, 'like', im));

%% Generate mask:

im_lab2 = rgb2lab(finalsegmentation);

% Get the L channel
L2 = im_lab2(:,:,1);
L2_values =L2(:);
L2_values(L2_values == 0) = [];

% Check on a lower percentile 

P702= prctile(L2_values,70);

new_mask2=zeros(size(L2));

new_mask2(L2<P702)=1;
new_mask2(L2==0)=0;
new_mask2=logical(new_mask2);
%% Morphology to remove clearly not cells:

new_mask2 = bwpropfilt(new_mask2,'Eccentricity',[0, 0.98]);
new_mask2 = bwpropfilt(new_mask2,'Area',[50, 2822500000]);

%% fill very tiny holes=
new_mask2 = ~bwareaopen(~new_mask2, 150);

end
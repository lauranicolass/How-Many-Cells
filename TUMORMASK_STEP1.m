
clear;clc;close all
currentFolder = pwd;
foldersave=fullfile(currentFolder,'results');
if ~exist(foldersave, 'dir')
       mkdir(foldersave)
end
%% Add bf directory to open image
directoryome=fullfile(currentFolder,'bfmatlab');
%% Add ABANICCO directories for color analysis
directoryABANICCO=fullfile(currentFolder,'ABANICCO');
directory2=fullfile(directoryABANICCO,'data');
addpath(directoryABANICCO,directory2,directoryome)
%% Load data needed for ABANICCO
load(fullfile(directory2,'Regions_Angles.mat'))
load(fullfile(directory2,'Regions_Angles1.mat'))

%% Load the image and save it
filename=fullfile(currentFolder,'OS-3-cropped.ome.tif');
reading=bfopen(filename);

channel1=reading{1, 1}{1, 1}  ;
channel2=reading{1, 1}{2, 1}  ;
channel3=reading{1, 1}{3, 1}  ;
rgbImage = cat(3, channel1, channel2, channel3);

filenamesave=fullfile(foldersave,'original image.png');
imwrite(rgbImage,filenamesave)
%% Remove background

% Filter out noisy dye:

h = ones(5,5)/20;
rgb2 = imfilter(rgbImage,h);

% Perform automatic background segmentation:

[BW2, threshold2]=  thresholdfromminL(rgbImage,0);
segmented_image = bsxfun(@times, rgbImage, cast(BW2,class(rgbImage)));



%% RUN ABANICCO

wantfigure=1; % change to 0 if uninterested in obtaining figures
numberofshades=15; % number of colors detected per category
morphology=1; 

[Results,Regions_Angles1a,subTablesa] = AnalyzeColorImage_final2_short(segmented_image, Regions_Angles,Regions_Angles1,numberofshades,morphology,wantfigure);


%% CLUSTER BROWN + YELLOW AFTER CHECKING THE POLAR DESCRIPTION BY REDIFINING THE BOUNDARIES:

an_im=segmented_image;

% re-convert to lab:

imlab=rgb2lab(an_im);
a=imlab(:,:,2); A=a(:);
b=imlab(:,:,3); B=b(:);
points=[A B];
AB=[A B];

[thetas,rhos] = cart2pol(AB(:,2),AB(:,1));

thetas2=wrapTo360(rad2deg( thetas(:)));

ABpolar=[thetas rhos];

% Using the polar description decide the new angles and radious of the
% region: We are creating a new class with all the possible reds, oranges
% and browns. From the polar description we know in this image there are
% only browns in this section

newtheta1=0;
newtheta2=90;
rhonew1=10;

indbk1=find(thetas2>newtheta1);
indbk2=find(thetas2<newtheta2);
indbk3=find(rhos>rhonew1);

ABC_inter=intersect(intersect(indbk1,indbk2,'stable'),indbk3,'stable');

keepbk=zeros(size(A));
keepbk(ABC_inter)=1;
maskbk=reshape(keepbk,size(a));

% Now we also add the yellow class
ind_yellow=find(strcmp({Results.Name}.','Yellow'));
yellowmask=Results(ind_yellow).Resultingmask;
maskwithyellow=logical(maskbk+yellowmask);
bk_new3 = bsxfun(@times, an_im, cast(maskwithyellow,class(an_im)));
figure;imshow(bk_new3);title('The new cluster segmentation brown + yellow r>10','FontSize',15,FontName='Arial')



%% Lets keep the most relevant areas: Post-Processing of tumor mask

% Using morphology, eliminate super tiny objects - we want areas

maskwithyellow2 = bwareaopen(maskwithyellow,200);
maskwithyellow2 = ~bwareaopen(~maskwithyellow2, 200);
gaussed=imgaussfilt(double(maskwithyellow2),10);


% normalize and segment the "foreground":

% Normalize input data to range in [0,1].
Xmin = min(gaussed(:));
Xmax = max(gaussed(:));
if isequal(Xmax,Xmin)
    gaussed = 0*gaussed;
else
    gaussed = (gaussed - Xmin) ./ (Xmax - Xmin);
end

% Threshold image - global threshold
BW = imbinarize(gaussed);

% Create masked image.
maskedImage_tumor = gaussed;
maskedImage_tumor(~BW) = 0;

maskedImage_tumor=logical(maskedImage_tumor.*BW2);
inverse=imcomplement(maskedImage_tumor);
thetumor_segmented=bsxfun(@times, rgbImage, cast(maskedImage_tumor,class(rgbImage)));
figure;imshow(thetumor_segmented,[]);title('The Tumor','FontSize',15,FontName='Arial')
% show mask over image:
figure;imshowpair(rgbImage,maskedImage_tumor);title('Tumoral Mask over image','FontSize',15,FontName='Arial')

filenamesaveinicropped=fullfile(foldersave,'segmented_tumor.png');
imwrite(thetumor_segmented,filenamesaveinicropped)
filenamesaveinicropped=fullfile(foldersave,'segmented_tumor_mask.png');
imwrite(maskedImage_tumor,filenamesaveinicropped)
%% Lets apply slightly more post-processing to remove as much background as possible:

% lets clear unnecessary things:
clearvars -except rgbImage  maskedImage_tumor thetumor_segmented BW3 foldersave reading segmented_image3 Regions_Angles Regions_Angles1

%% fill very small holes and remove small objects
% thetumor_segmentedbw=im2gray(thetumor_segmented);
% thetumor_segmentedbw_BW=zeros(size(thetumor_segmentedbw));
% thetumor_segmentedbw_BW(thetumor_segmentedbw>0)=1;
thetumor_segmentedbw_BW = maskedImage_tumor;
thetumor_segmentedbw_BW2 = ~bwareaopen(~thetumor_segmentedbw_BW, 50);
thetumor_segmentedbw_BW3 = bwareaopen(thetumor_segmentedbw_BW2, 50);


thetumor_segmented3=bsxfun(@times, rgbImage, cast(thetumor_segmentedbw_BW3,class(rgbImage)));

figure;imshowpair(rgbImage,thetumor_segmentedbw_BW3);title('Tumoral Mask Better','FontSize',15,FontName='Arial')

filenamesave=fullfile(foldersave,'segmented_tumor_better.png');
imwrite(thetumor_segmented3,filenamesave)

filenamesave=fullfile(foldersave,'segmented_tumor_better_mask.png');
imwrite(thetumor_segmentedbw_BW3,filenamesave)

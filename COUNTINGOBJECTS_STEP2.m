clear;clc;close all


currentFolder = pwd;
foldersave0=fullfile(currentFolder,'results');
if ~exist(foldersave0, 'dir')
       mkdir(foldersave0)
end

% Read the original image and the segmented tumor area:
img0 = imread(fullfile(foldersave0,'original image.png'));
img = imread(fullfile(foldersave0,'segmented_tumor_better.png'));

% Set the size of the tiles
tile_size = [500 500];

% Set the overlap between the tiles (in pixels)
overlap = 50;

% Get the size of the image
[img_height, img_width, ~] = size(img);

% Calculate the number of rows and columns of tiles
n_rows = ceil((img_height - overlap) / (tile_size(1) - overlap));
n_cols = ceil((img_width - overlap) / (tile_size(2) - overlap));

% Initialize masks
finalmask0=zeros(size(rgb2gray(img)));
finalmask=finalmask0;


% Create the tiles
for row = 1:n_rows
  for col = 1:n_cols
    % Calculate the starting and ending row and column indices for the current tile
    start_row = (row-1)*(tile_size(1) - overlap) + 1;
    end_row = min(start_row + tile_size(1) - 1, img_height);
    start_col = (col-1)*(tile_size(2) - overlap) + 1;
    end_col = min(start_col + tile_size(2) - 1, img_width);
    
    % Extract the current tile and apply the adaptative threshold
    % SuperCIELAB
    tile = img(start_row:end_row, start_col:end_col, :);
    [new_mask2]=AdptThresholdSuperCielab(tile);

    % Map the results to the full mask
    finalmask0(start_row:end_row, start_col:end_col)=new_mask2;

    finalmask=finalmask+finalmask0;
    finalmask0=zeros(size(rgb2gray(img)));
   
  end
end

filenamesave=fullfile(foldersave0,'adaptedtrhesholdmask_finalmask.png');
imwrite(finalmask,filenamesave)


%% Use morphology to separate objects a bit:

BW2 = bwmorph(finalmask,'tophat');
figure;imshowpair(finalmask,finalmask-BW2);
figure;montage({finalmask,finalmask-BW2})
finalmask=logical(finalmask-BW2);
finalsegmentation3=bsxfun(@times, img, cast(finalmask, 'like', img));

% Show results
figure;imshow(finalmask);title('Final Tumor Mask','FontSize',15,FontName='Arial')

figure;imshowpair(finalmask,img0,'ColorChannels','red-cyan');title('Final Tumor Mask over Original Image','FontSize',15,FontName='Arial')

% Save results
filenamesave1=fullfile(foldersave0,'adaptedtrhesholdmask_finalmask_withmorphology.png');
imwrite(finalmask,filenamesave1)

filenamesave2=fullfile(foldersave0,'finalsegmentation_adpthreshandmorpho.png');
imwrite(finalsegmentation3,filenamesave2)

%% Counting

% Find regions
CC=bwconncomp(finalmask);
stats = regionprops(CC);
Area = [stats.Area].';

% Eliminate small objects that cannot be cells
stats(Area<150)=[];

% Count how many possible cells would fit in each region
for i=1:length(stats)

    
if stats(i).Area>150 &&stats(i).Area<350
    numcells=1;
    stats(i).numcells=numcells;
else

numcells=floor(stats(i).Area/350);

% When regions are too big, we overestimate, this takes care of that
    % somewhat
if numcells>10
howmany10=floor(numcells/10);
numcells=numcells-2*howmany10;
elseif numcells>5
howmany5=floor(numcells/5);
numcells=numcells-howmany5;
end
stats(i).numcells=numcells;

end
end

cells_in_tile=sum([stats.numcells].')

%% Uncomment this to see the caos of all the regions marked over the iamge
% figure;imshow(finalsegmentation3)
% hold on
% for k = 1:length(stats)
%      BB = stats(k).BoundingBox;
%      rectangle('Position', [BB(1),BB(2),BB(3),BB(4)],'EdgeColor','r','LineWidth',2) ;
% end

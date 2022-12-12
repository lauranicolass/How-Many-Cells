% Read the image
img = imread(' '); % fill this in

% Set the size of the tiles
tile_size = [500 500];

% Set the folder to save the tiles
foldersave=' '; % fill this in

% Set the overlap between the tiles (in pixels)
overlap = 50;

% Get the size of the image
[img_height, img_width, ~] = size(img);

% Calculate the number of rows and columns of tiles
n_rows = ceil((img_height - overlap) / (tile_size(1) - overlap));
n_cols = ceil((img_width - overlap) / (tile_size(2) - overlap));

% Initialize a cell array to store the tiles
% tiles = cell(n_rows, n_cols);
index=1;
% Create the tiles
for row = 1:n_rows
  for col = 1:n_cols
    % Calculate the starting and ending row and column indices for the current tile
    start_row = (row-1)*(tile_size(1) - overlap) + 1;
    end_row = min(start_row + tile_size(1) - 1, img_height);
    start_col = (col-1)*(tile_size(2) - overlap) + 1;
    end_col = min(start_col + tile_size(2) - 1, img_width);
    
    % Extract the current tile
    tile = img(start_row:end_row, start_col:end_col, :);

    namestring=strcat('cropped_sr',num2str(start_row),'_er',num2str(end_row),'_sc',num2str(start_col),'_ec',num2str(end_col),'.png');

    filenamesave=fullfile(foldersave,namestring);
    imwrite(tile,filenamesave)
    % Store the tile in the cell array
    structure_tiles(index).Name = namestring;
    structure_tiles(index).Tile = tile;
    index=index+1;
  end
end




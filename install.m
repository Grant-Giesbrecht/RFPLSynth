% List of relative directories (relative to install.m's location)
folders = [fullfile("src", "SRFT"), fullfile("src", "Synth")];

% Find out where 'install.m' is saved
file_path = mfilename('fullpath'); % Get full path to this file
if ismac || isunix
	trim_idx = find(file_path=='/', 1, 'last'); % Find index for trimming to directory
elseif ispc % Handle Windows' weird directory system
	trim_idx = find(file_path=='\', 1, 'last'); % Find index for trimming to directory
else % Else treat same as mac. Different statement in case new logic to be added
	trim_idx = find(file_path=='/', 1, 'last'); % Find index for trimming to directory
end
local_dir = file_path(1:trim_idx-1);

% cd to directory with 'install.m'
cd(local_dir);

% Add each listed subdirectory
first = true;
for fldr = folders
	
	% If not first addition, move back to base directory
	if ~first
		cd ..
	end
	first = false;
	
	% Change to folder
	cd(fullfile(local_dir, fldr));
	newpath = pwd;
	disp(['Adding to path: >>', newpath, '<<']);
	addpath(newpath);
	

end

successful = true;

if (savepath == 0)
    disp(' ')
    disp('***************************************************************');
    disp('*              Path was updated successfully                  *'); 
    disp('***************************************************************');
    disp(' ');
    disp('Now upon starting MATLAB the files in this repository will be');
    disp('accessible as functions. If you would like to view your current');
    disp('MATLAB path, typing "path" into the command prompt will display');
    disp('it.');
else
    disp(' ')
    disp('***************************************************************');
    disp('*              ERROR: Failed to update path.                  *'); 
    disp('***************************************************************');
	
	successful = false;
end
cd ..


%=========================================================================%
%				Check if neccesary toolboxes are installed				  %

toolboxes = ["Control System Toolbox", "Optimization Toolbox", "RF Toolbox" ];
missing = [];
any_missing = false;
for t = toolboxes
	
	if ~any(any(contains(struct2cell(ver), t)))
		
		if ~any_missing
			disp(' ')
			disp('***************************************************************');
			disp('*         ERROR: Missing one or more required toolboxs.       *'); 
			disp('***************************************************************');
			any_missing = true;
			
			successful = false;
		end
		
		missing = addTo(missing, t);
	end
	
end

if any_missing
	disp(' ');
	disp(" Missing Toolboxes:");
	
	for mt = missing
		displ("    ", mt);
	end
end

if ~successful
	warning off backtrace
	warning("Package not ready. Details in the messages above.");
	warning on backtrace
end





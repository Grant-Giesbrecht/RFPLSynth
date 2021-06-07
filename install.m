cd src
newpath = pwd;
disp(['Adding to path: >>', newpath, '<<']);
% addpath(newpath);

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





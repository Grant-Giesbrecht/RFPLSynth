classdef Netlist < handle
	
	properties
		
		components
		
	end
	
	methods
		function obj = Netlist(comp)
			obj.components = comp;
		end
		
		function add(obj, elmnt)
			
			obj.components = addTo(obj.components, elmnt);
		end
		
		function purge(obj, varargin)
			
			%TODO: Fix how this works when not just ladder, removing
			%elements should instead replace them with short, later
			%simplify short by removing parallel, renaming, etc.
			
			p = inputParser;
			p.addParameter('Zopen', 100e6, @isnumeric);
			p.addParameter('Zshort', 1e-3, @isnumeric);
			p.addParameter('f_low', 1e6, @isnumeric);
			p.addParameter('f_high', 1e9, @isnumeric);
			p.parse(varargin{:});
			
			Z_open = p.Results.Zopen;
			Z_short = p.Results.Zshort;
			freqs = [p.Results.f_low, p.Results.f_high];
			
			% Scan over all elements
			pop_idx = []; % Indeces of elements to delete
			replacements = []; %Node to rename with other
			idx = 0;
			for elmt=obj.components
				idx = idx + 1;
				
				% Get impedances at all test points
					Zs = abs(elmt.Z(freqs));
				
				if strcmp(elmt.nodes(2), "GND") %If is an admittance...
					
					% If element is open at all points, delete
					if all( Zs > Z_open)
						pop_idx = addTo(pop_idx, idx);
						
						% If brides two nodes, add to replacement list
						if numel(elmt.nodes) > 1
							s = struct('fnd', elmt.nodes(2:end), 'rep', elmt.nodes(1));
							replacements = addTo(replacements, s);
						end
					end
					
				else % Else if an impedance
					
					% If element is shorted at all points, delete
					if all( Zs < Z_short)
						pop_idx = addTo(pop_idx, idx);
						
						% If brides two nodes, add to replacement list
						if numel(elmt.nodes) > 1
							idx = 2;
							for idx = 2:numel(elmt.nodes) % Loop over all nodes (if more than 2 present)
								s = struct('fnd', elmt.nodes(idx), 'rep', elmt.nodes(1));
								replacements = addTo(replacements, s);
							end
							
						end
						
					end
					
				end
				
			end
			
			% Delete marked elements
			obj.components(pop_idx) = [];
			
			%Rename replaced nodes
			for elmt = obj.components % For each element
				
				% Check each find/replacement pair
				for r = replacements 
					
					% Scan over all nodes
					for ni = 1:length(elmt.nodes)
						
						% If nodes match
						if strcmp(elmt.nodes(ni), r.fnd)
							
							% Replace with replacement value
							elmt.nodes(ni) = r.rep;
						end
						
					end
					
				end
			end
			
		end
		
		function s = str(obj)
			
			s = "";
			
			% Display result
			displ("Scaled Circuit Output:");
			for c=obj.components
				s = strcat(s, "  ", c.str());
				s = s + newline;
			end
			
		end
		
	end
	
end
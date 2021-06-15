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
			
			%TODO: Fix node names for removed elements (ie. n1-n2-n3,
			%remove first element and n1 and n2 are now broken, one needs
			%to be renamed).
			
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
			pop_idx = [];
			idx = 0;
			for elmt=obj.components
				idx = idx + 1;
				
				% Get impedances at all test points
					Zs = abs(elmt.Z(freqs));
				
				if strcmp(elmt.nodes(2), "GND") %If is an admittance...
					
					% If element is open at all points, delete
					if all( Zs > Z_open)
						pop_idx = addTo(pop_idx, idx);
					end
					
				else % Else if an impedance
					
					% If element is shorted at all points, delete
					if all( Zs < Z_short)
						pop_idx = addTo(pop_idx, idx);
					end
					
				end
				
			end
			
			% Delete marked elements
			obj.components(pop_idx) = [];
			
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
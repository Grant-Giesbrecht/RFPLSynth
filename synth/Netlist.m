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
			for elmt=obj.circ
				idx = idx + 1;
				
				% Scale by Z0
				if strcmp(elmt.nodes(2), "GND") %If is an admittance...
					
					% Get impedances at all test points
					Zs = elmt.Z(freqs);
					
					% If element is open at all points, delete
					if all( Zs > Z_open)
						pop_idx = addTo(pop_idx, idx);
					end
					
				else % Else if an impedance
					elmt.val = elmt.val*synth_Z0_scale;
				end
				
				
			end
			
		end
		
		function s = str(obj)
			
			% Display result
			displ("Scaled Circuit Output:");
			for c=synth.circ
				displ("  ", c.str());
			end
			
		end
		
	end
	
end
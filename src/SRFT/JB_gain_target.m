function gain_t = JB_gain_target(s)
% JB_GAIN_TARGET This function calculates the target gain as a constant
% value, by looking
% at the minimum gain available by providing an ideal match for the first
% stage and the generator. This is discussed in Appendix A and is disclosed
% by the authors as not being the actual maximum gain/ ie. is not the ideal
% target gain, but the math for that ideal gain is ugly.
%
% JB_GAIN_TARGET(S) Calculates the gain target value from the S-parameter
% object S. Returns the maximum gain as a linear value, not in dB.
%
% 

	gain_t = -1;

	for f=1:length(s.Frequencies) % For each frequency
		
		% Calculate the max gain for that frequency point
		newval = abs( s.Parameters(2, 1, f))^2/(1 - abs(s.Parameters(1, 1, f))^2);
		
		% Select minimum gain
		if gain_t == -1 || gain_t > newval
			gain_t = newval;
		end
	end

end
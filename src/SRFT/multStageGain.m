function T = multStageGain(e21, e22, S11, S21)

	T = abs(e21).^2 .* abs(S21).^2 ./ abs(1 - e22.*S11).^2;

end
% get the envolopes to see if they have info for stuck SV detection

load batteryEffect\005deg_fast_slow_nom_stuck-mid_LVO\AET8661000_10_LVO_11k0V_12k5A_mdf_3Norm.MAT
plotXYwithEnvolop(signale.Zeit.daten,signale.Current_30.daten, 9, 'AET8661000_10_LVO_11k0V_12k5A_mdf_3Norm');


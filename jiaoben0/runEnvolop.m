% get the envolopes to see if they have info for stuck SV detection
figure(1)
load batteryEffect\005deg_fast_slow_nom_stuck-mid_LVO\AET8661000_10_LVO_11k0V_12k5A_mdf_1Fast.MAT
plotXYwithEnvolop(signale.Zeit.daten,signale.Current_10.daten, 6, 'AET8661000_10_LVO_11k0V_12k5A_mdf_1Fast');
figure(2)
load batteryEffect\005deg_fast_slow_nom_stuck-mid_LVO\AET8661000_10_LVO_11k0V_12k5A_mdf_2Slow.MAT
plotXYwithEnvolop(signale.Zeit.daten,signale.Current_20.daten, 6, 'AET8661000_10_LVO_11k0V_12k5A_mdf_2Slow');
figure(3)
load batteryEffect\005deg_fast_slow_nom_stuck-mid_LVO\AET8661000_10_LVO_11k0V_12k5A_mdf_3Norm.MAT
plotXYwithEnvolop(signale.Zeit.daten,signale.Current_30.daten, 6, 'AET8661000_10_LVO_11k0V_12k5A_mdf_3Norm');
figure(4)
load batteryEffect\005deg_fast_slow_nom_stuck-mid_LVO\AET8661000_10_LVO_11k0V_12k5A_mdf_4Stuck_mid.MAT
plotXYwithEnvolop(signale.Zeit.daten,signale.Current_40.daten, 6, 'AET8661000_10_LVO_11k0V_12k5A_mdf_4Stuck_mid');

figure(5)
load batteryEffect\110deg_fast_stuck-cl_nom_stuck-op_LVO_0\AET8521000_10_LVO_13k5V_14k0A_mdf_1Fast.MAT
plotXYwithEnvolop(signale.Zeit.daten,signale.Current_10.daten, 6, 'AET8521000_10_LVO_13k5V_14k0A_mdf_1Fast');

figure(6)
load batteryEffect\110deg_fast_stuck-cl_nom_stuck-op_LVO_0\AET8521000_10_LVO_13k5V_14k0A_mdf_2Stuck_cl.MAT
plotXYwithEnvolop(signale.Zeit.daten,signale.Current_20.daten, 6, 'AET8521000_10_LVO_13k5V_14k0A_mdf_2Stuck_cl');

figure(7)
load batteryEffect\110deg_fast_stuck-cl_nom_stuck-op_LVO_0\AET8521000_10_LVO_13k5V_14k0A_mdf_3Norm.MAT
plotXYwithEnvolop(signale.Zeit.daten,signale.Current_30.daten, 6, 'AET8521000_10_LVO_13k5V_14k0A_mdf_3Norm');

figure(8)
load batteryEffect\110deg_fast_stuck-cl_nom_stuck-op_LVO_0\AET8521000_10_LVO_13k5V_14k0A_mdf_4Stuck_op.MAT
plotXYwithEnvolop(signale.Zeit.daten,signale.Current_40.daten, 6, 'AET8521000_10_LVO_13k5V_14k0A_mdf_4Stuck_op');

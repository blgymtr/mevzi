// data/real_combat.json üreticisi (roadmap 49/50/51): birim başına gerçek zırh (mm RHA), can, silah menzilleri,
// optik sınıfı, APS / kafes zırh. Değerler yayımlanmış açık kaynak tahminlerinden yaklaşık.
const fs = require('fs');
const U = {};
// a(KEf, KEs, KEr, KEt, CEf, CEs, CEr, CEt)
function A(kf, ks, kr, kt, cf, cs, cr, ct) { return [[kf, ks, kr, kt], [cf, cs, cr, ct]]; }
function put(id, o) { U[id] = o; }

// ---------------------------------------------------------------- ABD
// tanklar: 120 mm M256 (APFSDS etkili ~3500 m), M2 12,7 mm, eşeksenli 7,62
put('usa_mbt_a1', { arm: A(600, 70, 40, 35, 1000, 240, 60, 35), hp: 900, rng: { main: 3500, mg: 1800 }, opt: 'th' });
put('usa_mbt_a2', { arm: A(620, 70, 40, 35, 1050, 240, 60, 35), hp: 920, rng: { main: 3500, mg: 1800 }, opt: 'th3' });
put('usa_mbt_s2', { arm: A(660, 90, 40, 40, 1100, 400, 60, 40), hp: 950, rng: { main: 4000, mg: 1800 }, opt: 'th3', slat: true });
put('usa_mbt_s3', { arm: A(700, 100, 45, 40, 1160, 450, 70, 40), hp: 980, rng: { main: 4000, mg: 1800 }, opt: 'th3', aps: true });
put('usa_mbt_e3', { arm: A(700, 110, 50, 45, 1160, 480, 80, 45), hp: 900, rng: { main: 4000, mg: 1800 }, opt: 'th3', aps: true });
put('usa_lt_m10', { arm: A(160, 40, 25, 20, 200, 60, 30, 20), hp: 620, rng: { main: 3000, mg: 1800 }, opt: 'th3' });
// ZPT
put('usa_apc_113', { arm: A(20, 15, 15, 12, 20, 15, 15, 12), hp: 380, rng: { mg: 1800 }, opt: 'day' });
put('usa_apc_ampv', { arm: A(90, 45, 30, 20, 160, 90, 40, 20), hp: 520, rng: { mg: 1800 }, opt: 'th' });
put('usa_apc_icv', { arm: A(40, 30, 25, 15, 60, 200, 60, 15), hp: 450, rng: { mg: 1800 }, opt: 'th', slat: true });
put('usa_apc_guard', { arm: A(20, 18, 15, 12, 20, 18, 15, 12), hp: 320, rng: { mg: 1800 }, opt: 'day' });
put('usa_apc_aav', { arm: A(25, 20, 18, 12, 60, 40, 20, 12), hp: 460, rng: { mg: 1500 }, opt: 'day' });
put('usa_apc_acvp', { arm: A(45, 30, 25, 15, 70, 50, 30, 15), hp: 480, rng: { mg: 1800 }, opt: 'th' });
// PSA: 25 mm M242 (APFSDS ~2000 m), TOW-2B 3750 m
put('usa_ifv_m2a3', { arm: A(110, 45, 30, 20, 150, 90, 40, 20), hp: 620, rng: { auto: 2200, atgm: 3750, mg: 1100 }, opt: 'th3' });
put('usa_ifv_m2a4', { arm: A(120, 50, 30, 20, 380, 300, 40, 20), hp: 660, rng: { auto: 2200, atgm: 3750, mg: 1100 }, opt: 'th3' });
put('usa_ifv_m3a3', { arm: A(110, 45, 30, 20, 150, 90, 40, 20), hp: 620, rng: { auto: 2200, atgm: 3750, mg: 1100 }, opt: 'th3', recon: true });
put('usa_ifv_drag', { arm: A(50, 35, 25, 15, 70, 200, 60, 15), hp: 480, rng: { auto: 2500, mg: 1100 }, opt: 'th', slat: true });
put('usa_ifv_acv30', { arm: A(50, 30, 25, 15, 70, 50, 30, 15), hp: 500, rng: { auto: 2500, mg: 1100 }, opt: 'th' });
put('usa_ifv_lav25', { arm: A(30, 20, 15, 10, 30, 20, 15, 10), hp: 380, rng: { auto: 2200, mg: 1100 }, opt: 'th', recon: true });
// tank avcıları
put('usa_td_atgm', { arm: A(40, 30, 25, 15, 60, 200, 60, 15), hp: 440, rng: { atgm: 3750, mg: 1800 }, opt: 'th3', slat: true });
put('usa_td_tow', { arm: A(15, 12, 10, 8, 15, 12, 10, 8), hp: 180, rng: { atgm: 3750, mg: 1800 }, opt: 'th3' });
put('usa_td_lavat', { arm: A(30, 20, 15, 10, 30, 20, 15, 10), hp: 380, rng: { atgm: 3750, mg: 1100 }, opt: 'th3' });
put('usa_td_mgs', { arm: A(45, 30, 25, 15, 65, 200, 60, 15), hp: 450, rng: { main: 2500, mg: 1800 }, opt: 'th', slat: true });
put('usa_td_itv', { arm: A(20, 15, 15, 12, 20, 15, 15, 12), hp: 380, rng: { atgm: 3750, mg: 1800 }, opt: 'th' });
put('usa_td_ontos', { arm: A(13, 13, 10, 8, 13, 13, 10, 8), hp: 260, rng: { main: 1100, mg: 1000 }, opt: 'day' });
// kundağı motorlu obüs (dolaylı azami menzil, doğrudan atışta 12,7 mm)
put('usa_spg_a6', { arm: A(30, 25, 20, 15, 30, 25, 20, 15), hp: 420, rng: { ind: 30000, mg: 1800 }, opt: 'day' });
put('usa_spg_a7', { arm: A(45, 30, 25, 15, 60, 40, 25, 15), hp: 460, rng: { ind: 30000, mg: 1800 }, opt: 'day' });
put('usa_spg_m110', { arm: A(13, 13, 10, 0, 13, 13, 10, 0), hp: 360, rng: { ind: 25000 }, opt: 'eye' });
put('usa_spg_m107', { arm: A(13, 13, 10, 0, 13, 13, 10, 0), hp: 340, rng: { ind: 32700 }, opt: 'eye' });
put('usa_spg_m52', { arm: A(25, 20, 15, 12, 25, 20, 15, 12), hp: 360, rng: { ind: 11300, mg: 1800 }, opt: 'eye' });
// çekili toplar (zırhsız; kalkan ~6 mm)
put('usa_tow_m777', { arm: A(6, 0, 0, 0, 6, 0, 0, 0), hp: 300, rng: { ind: 30000 }, opt: 'eye' });
put('usa_tow_m119', { arm: A(6, 0, 0, 0, 6, 0, 0, 0), hp: 260, rng: { ind: 19500, main: 1500 }, opt: 'eye' });
put('usa_tow_m198', { arm: A(6, 0, 0, 0, 6, 0, 0, 0), hp: 320, rng: { ind: 30000 }, opt: 'eye' });
put('usa_tow_m102', { arm: A(5, 0, 0, 0, 5, 0, 0, 0), hp: 240, rng: { ind: 15100, main: 1500 }, opt: 'eye' });
put('usa_tow_m114', { arm: A(6, 0, 0, 0, 6, 0, 0, 0), hp: 300, rng: { ind: 14600 }, opt: 'eye' });
put('usa_tow_m101', { arm: A(6, 0, 0, 0, 6, 0, 0, 0), hp: 260, rng: { ind: 11300, main: 1500 }, opt: 'eye' });
// roketatar (oyun haritasında stratejik füzeler harita boyu sınırlanır)
put('usa_mlrs_himars', { arm: A(12, 10, 10, 6, 12, 10, 10, 6), hp: 300, rng: { ind: 70000 }, opt: 'eye' });
put('usa_mlrs_m270', { arm: A(20, 15, 15, 10, 20, 15, 15, 10), hp: 380, rng: { ind: 40000 }, opt: 'eye' });
put('usa_mlrs_m270a1', { arm: A(20, 15, 15, 10, 20, 15, 15, 10), hp: 400, rng: { ind: 70000 }, opt: 'eye' });
put('usa_mlrs_m270a2', { arm: A(25, 18, 15, 10, 25, 18, 15, 10), hp: 420, rng: { ind: 70000 }, opt: 'eye' });
put('usa_mlrs_typhon', { arm: A(8, 6, 6, 4, 8, 6, 6, 4), hp: 280, rng: { ind: 100000 }, opt: 'eye' });
put('usa_mlrs_lrhw', { arm: A(8, 6, 6, 4, 8, 6, 6, 4), hp: 280, rng: { ind: 100000 }, opt: 'eye' });
// havanlar
put('usa_mor_60', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 120, rng: { ind: 3490 }, opt: 'eye' });
put('usa_mor_81', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 150, rng: { ind: 5935 }, opt: 'eye' });
put('usa_mor_120', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 180, rng: { ind: 7240 }, opt: 'eye' });
put('usa_mor_1064', { arm: A(20, 15, 15, 12, 20, 15, 15, 12), hp: 380, rng: { ind: 7240, mg: 1800 }, opt: 'day' });
put('usa_mor_1129', { arm: A(40, 30, 25, 15, 60, 200, 60, 15), hp: 440, rng: { ind: 7240, mg: 1800 }, opt: 'th', slat: true });
put('usa_mor_1287', { arm: A(90, 45, 30, 20, 160, 90, 40, 20), hp: 500, rng: { ind: 7240, mg: 1800 }, opt: 'th' });
// hava savunma: aa = havadaki hedefe azami menzil (radar/arayıcı), mg/auto = kara hedefi
put('usa_aa_pac3', { arm: A(10, 8, 8, 5, 10, 8, 8, 5), hp: 300, rng: { aa: 40000 }, opt: 'rad', radar: 150000 });
put('usa_aa_shorad', { arm: A(40, 30, 25, 15, 60, 200, 60, 15), hp: 440, rng: { aa: 4800, auto: 2500, atgm: 8000 }, opt: 'th3', radar: 15000, slat: true });
put('usa_aa_avenger', { arm: A(15, 12, 10, 8, 15, 12, 10, 8), hp: 180, rng: { aa: 4800, mg: 1800 }, opt: 'th', radar: 10000 });
put('usa_aa_cram', { arm: A(6, 4, 4, 2, 6, 4, 4, 2), hp: 320, rng: { aa: 1500 }, opt: 'rad', radar: 6000 });
put('usa_aa_nasams', { arm: A(8, 6, 6, 4, 8, 6, 6, 4), hp: 260, rng: { aa: 25000 }, opt: 'rad', radar: 75000 });
put('usa_aa_stinger', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 100, rng: { aa: 4800 }, opt: 'eye' });
// istihkâm
put('usa_eng_abv', { arm: A(580, 70, 40, 35, 900, 240, 60, 35), hp: 900, rng: { mg: 1800 }, opt: 'day' });
put('usa_eng_ace', { arm: A(25, 20, 15, 10, 25, 20, 15, 10), hp: 520, rng: {}, opt: 'eye' });
put('usa_eng_wolv', { arm: A(580, 70, 40, 35, 900, 240, 60, 35), hp: 880, rng: { mg: 1800 }, opt: 'day' });
put('usa_eng_m88', { arm: A(60, 40, 30, 20, 60, 40, 30, 20), hp: 820, rng: { mg: 1800 }, opt: 'day' });
put('usa_eng_husky', { arm: A(15, 15, 12, 8, 15, 15, 12, 8), hp: 300, rng: {}, opt: 'th' });
put('usa_eng_d7', { arm: A(25, 20, 15, 10, 25, 20, 15, 10), hp: 700, rng: {}, opt: 'eye' });
// MRAP: 7,62 / 12,7 koruma, alt mayına dayanıklı
put('usa_mrap_matv', { arm: A(25, 22, 18, 10, 30, 25, 20, 10), hp: 340, rng: { mg: 1800 }, opt: 'th' });
put('usa_mrap_maxx', { arm: A(25, 22, 18, 10, 30, 25, 20, 10), hp: 380, rng: { mg: 1800 }, opt: 'day' });
put('usa_mrap_cou6', { arm: A(25, 22, 18, 10, 30, 25, 20, 10), hp: 420, rng: { mg: 1800 }, opt: 'day' });
put('usa_mrap_buff', { arm: A(25, 22, 18, 10, 30, 25, 20, 10), hp: 460, rng: { mg: 1800 }, opt: 'day' });
put('usa_mrap_rg33', { arm: A(25, 22, 18, 10, 30, 25, 20, 10), hp: 360, rng: { mg: 1800 }, opt: 'day' });
put('usa_mrap_caiman', { arm: A(25, 22, 18, 10, 30, 25, 20, 10), hp: 400, rng: { mg: 1800 }, opt: 'day' });
// hafif araçlar
put('usa_lv_m1151', { arm: A(12, 10, 8, 4, 12, 10, 8, 4), hp: 180, rng: { mg: 1800 }, opt: 'day' });
put('usa_lv_m1165', { arm: A(10, 8, 6, 4, 10, 8, 6, 4), hp: 170, rng: { mg: 1800 }, opt: 'day' });
put('usa_lv_jltv_gp', { arm: A(20, 18, 14, 8, 22, 20, 15, 8), hp: 240, rng: { mg: 1800 }, opt: 'th' });
put('usa_lv_jltv_cca', { arm: A(20, 18, 14, 8, 22, 20, 15, 8), hp: 230, rng: { mg: 1800 }, opt: 'th' });
put('usa_lv_isv', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 110, rng: { mg: 1100 }, opt: 'eye' });
put('usa_lv_isv_hv', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 110, rng: { mg: 1800 }, opt: 'eye' });
// saldırı helikopterleri: Hellfire 8000 m, 30 mm M230 1500-3000 m, Hydra 8000 m (alan)
put('usa_heli_ah64d', { arm: A(25, 15, 10, 8, 25, 15, 10, 8), hp: 650, rng: { atgm: 8000, auto: 3000, rkt: 6000 }, opt: 'th3', radar: 8000 });
put('usa_heli_ah64e', { arm: A(25, 15, 10, 8, 25, 15, 10, 8), hp: 700, rng: { atgm: 8000, auto: 3000, rkt: 6000 }, opt: 'th3', radar: 8000 });
put('usa_heli_ah1z', { arm: A(20, 12, 10, 6, 20, 12, 10, 6), hp: 560, rng: { atgm: 8000, auto: 2500, rkt: 6000 }, opt: 'th3' });
put('usa_heli_ah6', { arm: A(5, 4, 4, 2, 5, 4, 4, 2), hp: 280, rng: { auto: 1500, rkt: 5000 }, opt: 'th' });
put('usa_heli_dap', { arm: A(15, 10, 8, 6, 15, 10, 8, 6), hp: 560, rng: { atgm: 8000, auto: 3000, rkt: 6000 }, opt: 'th3' });
put('usa_heli_oh58', { arm: A(8, 6, 6, 4, 8, 6, 6, 4), hp: 260, rng: { atgm: 8000, mg: 1800, rkt: 6000 }, opt: 'th3', recon: true });
// nakliye helikopterleri (kapı makineli)
put('usa_heli_uh60', { arm: A(15, 10, 8, 6, 15, 10, 8, 6), hp: 520, rng: { mg: 1100 }, opt: 'th' });
put('usa_heli_ch47', { arm: A(15, 10, 8, 6, 15, 10, 8, 6), hp: 700, rng: { mg: 1100 }, opt: 'th' });
put('usa_heli_ch53', { arm: A(15, 10, 8, 6, 15, 10, 8, 6), hp: 760, rng: { mg: 1800 }, opt: 'th' });
put('usa_heli_uh1y', { arm: A(12, 8, 6, 4, 12, 8, 6, 4), hp: 420, rng: { mg: 1100 }, opt: 'th' });
put('usa_heli_uh72', { arm: A(4, 4, 4, 2, 4, 4, 4, 2), hp: 300, rng: {}, opt: 'th' });
put('usa_heli_mv22', { arm: A(15, 10, 8, 6, 15, 10, 8, 6), hp: 650, rng: { mg: 1100 }, opt: 'th' });
// İHA: hava aracı; görüş "uav" (yukarıdan bakış), silahlı olanlarda füze
put('usa_uav_mq1c', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 160, rng: { atgm: 8000 }, opt: 'uav' });
put('usa_uav_mq9', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 200, rng: { atgm: 8000 }, opt: 'uav' });
put('usa_uav_rq4', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 260, rng: {}, opt: 'uav', recon: true });
put('usa_uav_rq7', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 90, rng: {}, opt: 'uav', recon: true });
put('usa_uav_rq11', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 30, rng: {}, opt: 'uav' });
put('usa_uav_vbat', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 60, rng: {}, opt: 'uav' });

// ---------------------------------------------------------------- RUSYA
// 125 mm 2A46M (APFSDS ~3000 m) + namludan güdümlü füze 9M119 (5000 m); Kord 12,7; PKT 7,62
put('rus_mbt_72b', { arm: A(520, 80, 40, 30, 900, 250, 60, 30), hp: 820, rng: { main: 3000, atgm: 4000, mg: 1500 }, opt: 'day' });
put('rus_mbt_72b3', { arm: A(600, 110, 40, 35, 1100, 450, 70, 35), hp: 850, rng: { main: 3000, atgm: 5000, mg: 1500 }, opt: 'th' });
put('rus_mbt_80', { arm: A(600, 110, 40, 35, 1100, 420, 70, 35), hp: 860, rng: { main: 3000, atgm: 5000, mg: 1500 }, opt: 'th' });
put('rus_mbt_90a', { arm: A(640, 100, 40, 35, 1150, 380, 70, 35), hp: 880, rng: { main: 3000, atgm: 5000, mg: 1500 }, opt: 'th' });
put('rus_mbt_90m', { arm: A(720, 130, 45, 40, 1250, 500, 80, 40), hp: 920, rng: { main: 3500, atgm: 5000, mg: 1500 }, opt: 'th3', slat: true });
put('rus_mbt_14', { arm: A(840, 160, 60, 50, 1400, 560, 100, 50), hp: 960, rng: { main: 4000, atgm: 7000, mg: 1500 }, opt: 'th3', aps: true });
// ZPT: 14,5 mm KPVT (2000 m), BTR-82A 30 mm 2A72
put('rus_apc_btr80', { arm: A(14, 10, 8, 7, 14, 10, 8, 7), hp: 380, rng: { mg: 2000 }, opt: 'day' });
put('rus_apc_btr82', { arm: A(16, 12, 10, 7, 16, 12, 10, 7), hp: 420, rng: { auto: 2000, mg: 1500 }, opt: 'th' });
put('rus_apc_mtlb', { arm: A(14, 10, 10, 7, 14, 10, 10, 7), hp: 300, rng: { mg: 1500 }, opt: 'eye' });
put('rus_apc_mdm', { arm: A(15, 12, 10, 8, 15, 12, 10, 8), hp: 300, rng: { mg: 1500 }, opt: 'day' });
put('rus_apc_boom', { arm: A(60, 40, 30, 15, 120, 80, 40, 15), hp: 480, rng: { auto: 2000, atgm: 5500, mg: 1500 }, opt: 'th3' });
put('rus_apc_btrd', { arm: A(15, 10, 8, 6, 15, 10, 8, 6), hp: 280, rng: { mg: 1500 }, opt: 'eye' });
// PSA: 30 mm 2A42/2A72 (~2000 m), Konkurs 4000, Kornet 5500, BMP-3 100 mm + Arkan 5500
put('rus_ifv_bmp2', { arm: A(35, 18, 15, 10, 35, 18, 15, 10), hp: 480, rng: { auto: 2000, atgm: 4000, mg: 1500 }, opt: 'day' });
put('rus_ifv_bmp2m', { arm: A(35, 18, 15, 10, 35, 18, 15, 10), hp: 500, rng: { auto: 2000, atgm: 5500, mg: 1500 }, opt: 'th' });
put('rus_ifv_bmp3', { arm: A(60, 25, 18, 12, 70, 30, 20, 12), hp: 540, rng: { main: 4000, atgm: 5500, auto: 2000, mg: 1500 }, opt: 'day' });
put('rus_ifv_bmd4', { arm: A(35, 18, 12, 10, 35, 18, 12, 10), hp: 360, rng: { main: 4000, atgm: 5500, auto: 2000, mg: 1500 }, opt: 'th' });
put('rus_ifv_kurg', { arm: A(110, 50, 30, 20, 300, 200, 40, 20), hp: 560, rng: { auto: 2000, atgm: 5500, mg: 1500 }, opt: 'th3', aps: true });
put('rus_ifv_bmpt', { arm: A(560, 120, 40, 35, 1000, 450, 70, 35), hp: 860, rng: { auto: 2500, atgm: 6000, mg: 1500 }, opt: 'th3' });
// tank avcıları
put('rus_td_kornet', { arm: A(20, 18, 14, 8, 22, 20, 15, 8), hp: 220, rng: { atgm: 5500 }, opt: 'th3' });
put('rus_td_shturm', { arm: A(20, 14, 12, 10, 20, 14, 12, 10), hp: 300, rng: { atgm: 5000 }, opt: 'day' });
put('rus_td_khriz', { arm: A(60, 25, 18, 12, 70, 30, 20, 12), hp: 480, rng: { atgm: 6000 }, opt: 'th3', radar: 6000 });
put('rus_td_sprut', { arm: A(35, 18, 12, 10, 35, 18, 12, 10), hp: 400, rng: { main: 3000, atgm: 5000, mg: 1500 }, opt: 'th' });
put('rus_td_brdm', { arm: A(14, 10, 8, 6, 14, 10, 8, 6), hp: 240, rng: { atgm: 4000 }, opt: 'day' });
put('rus_td_sprutm', { arm: A(40, 20, 14, 10, 40, 20, 14, 10), hp: 420, rng: { main: 3000, atgm: 5000, mg: 1500 }, opt: 'th3' });
// kundağı motorlu obüs
put('rus_spg_msta', { arm: A(30, 20, 15, 15, 30, 20, 15, 15), hp: 440, rng: { ind: 29000, mg: 1500 }, opt: 'day' });
put('rus_spg_koal', { arm: A(45, 30, 20, 15, 60, 40, 25, 15), hp: 480, rng: { ind: 40000, mg: 1500 }, opt: 'th' });
put('rus_spg_akat', { arm: A(20, 15, 15, 12, 20, 15, 15, 12), hp: 380, rng: { ind: 24000, mg: 1500 }, opt: 'day' });
put('rus_spg_gvoz', { arm: A(20, 15, 10, 10, 20, 15, 10, 10), hp: 300, rng: { ind: 21900 }, opt: 'day' });
put('rus_spg_malka', { arm: A(13, 13, 10, 0, 13, 13, 10, 0), hp: 380, rng: { ind: 47500 }, opt: 'eye' });
put('rus_spg_malva', { arm: A(12, 10, 10, 6, 12, 10, 10, 6), hp: 300, rng: { ind: 30000 }, opt: 'day' });
// çekili
put('rus_tow_d30', { arm: A(6, 0, 0, 0, 6, 0, 0, 0), hp: 260, rng: { ind: 21900, main: 1500 }, opt: 'eye' });
put('rus_tow_mstab', { arm: A(6, 0, 0, 0, 6, 0, 0, 0), hp: 320, rng: { ind: 29000 }, opt: 'eye' });
put('rus_tow_giats', { arm: A(6, 0, 0, 0, 6, 0, 0, 0), hp: 340, rng: { ind: 33000 }, opt: 'eye' });
put('rus_tow_d20', { arm: A(6, 0, 0, 0, 6, 0, 0, 0), hp: 300, rng: { ind: 17400 }, opt: 'eye' });
put('rus_tow_d30a', { arm: A(6, 0, 0, 0, 6, 0, 0, 0), hp: 260, rng: { ind: 21900, main: 1500 }, opt: 'eye' });
put('rus_tow_nonak', { arm: A(5, 0, 0, 0, 5, 0, 0, 0), hp: 220, rng: { ind: 8700, main: 1000 }, opt: 'eye' });
// roketatar
put('rus_mlrs_grad', { arm: A(8, 6, 6, 4, 8, 6, 6, 4), hp: 260, rng: { ind: 20400 }, opt: 'eye' });
put('rus_mlrs_torg', { arm: A(8, 6, 6, 4, 8, 6, 6, 4), hp: 280, rng: { ind: 40000 }, opt: 'eye' });
put('rus_mlrs_urag', { arm: A(8, 6, 6, 4, 8, 6, 6, 4), hp: 300, rng: { ind: 35000 }, opt: 'eye' });
put('rus_mlrs_tors', { arm: A(8, 6, 6, 4, 8, 6, 6, 4), hp: 320, rng: { ind: 120000 }, opt: 'eye' });
put('rus_mlrs_tos', { arm: A(500, 80, 40, 30, 800, 250, 60, 30), hp: 820, rng: { ind: 6000 }, opt: 'day' });
put('rus_mlrs_isk', { arm: A(8, 6, 6, 4, 8, 6, 6, 4), hp: 300, rng: { ind: 500000 }, opt: 'eye' });
// havanlar
put('rus_mor_82', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 150, rng: { ind: 4270 }, opt: 'eye' });
put('rus_mor_120', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 180, rng: { ind: 7100 }, opt: 'eye' });
put('rus_mor_nonasvk', { arm: A(14, 10, 8, 7, 14, 10, 8, 7), hp: 380, rng: { ind: 12800, main: 1000, mg: 1500 }, opt: 'day' });
put('rus_mor_vasil', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 160, rng: { ind: 4270, main: 1000 }, opt: 'eye' });
put('rus_mor_nonas', { arm: A(15, 10, 8, 6, 15, 10, 8, 6), hp: 300, rng: { ind: 12800, main: 1000 }, opt: 'day' });
put('rus_mor_vena', { arm: A(16, 12, 10, 7, 16, 12, 10, 7), hp: 380, rng: { ind: 14000, main: 1000, mg: 1500 }, opt: 'th' });
// hava savunma
put('rus_aa_s400', { arm: A(10, 8, 8, 5, 10, 8, 8, 5), hp: 300, rng: { aa: 250000 }, opt: 'rad', radar: 400000 });
put('rus_aa_buk', { arm: A(20, 15, 12, 8, 20, 15, 12, 8), hp: 420, rng: { aa: 70000 }, opt: 'rad', radar: 120000 });
put('rus_aa_tor', { arm: A(20, 15, 12, 8, 20, 15, 12, 8), hp: 420, rng: { aa: 15000 }, opt: 'rad', radar: 32000 });
put('rus_aa_pantsir', { arm: A(12, 10, 8, 6, 12, 10, 8, 6), hp: 360, rng: { aa: 20000, auto: 4000 }, opt: 'rad', radar: 36000 });
put('rus_aa_tung', { arm: A(20, 15, 12, 8, 20, 15, 12, 8), hp: 420, rng: { aa: 8000, auto: 4000 }, opt: 'rad', radar: 18000 });
put('rus_aa_verba', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 100, rng: { aa: 6400 }, opt: 'eye' });
// istihkâm
put('rus_eng_imr', { arm: A(500, 80, 40, 30, 800, 220, 60, 30), hp: 800, rng: { mg: 1500 }, opt: 'day' });
put('rus_eng_brem', { arm: A(300, 70, 40, 30, 300, 120, 60, 30), hp: 780, rng: { mg: 1500 }, opt: 'day' });
put('rus_eng_mtu', { arm: A(500, 80, 40, 30, 800, 220, 60, 30), hp: 820, rng: {}, opt: 'day' });
put('rus_eng_ur77', { arm: A(14, 10, 10, 7, 14, 10, 10, 7), hp: 320, rng: {}, opt: 'eye' });
put('rus_eng_bat', { arm: A(14, 10, 10, 7, 14, 10, 10, 7), hp: 600, rng: {}, opt: 'eye' });
put('rus_eng_gmz', { arm: A(14, 10, 10, 7, 14, 10, 10, 7), hp: 360, rng: {}, opt: 'eye' });
// MRAP
put('rus_mrap_tyk', { arm: A(25, 22, 18, 10, 30, 25, 20, 10), hp: 420, rng: { mg: 1500 }, opt: 'th' });
put('rus_mrap_tyu', { arm: A(25, 22, 18, 10, 30, 25, 20, 10), hp: 380, rng: { mg: 1500 }, opt: 'day' });
put('rus_mrap_k53949', { arm: A(22, 20, 16, 8, 25, 22, 18, 8), hp: 360, rng: { mg: 1500 }, opt: 'day' });
put('rus_mrap_vdv', { arm: A(22, 20, 16, 8, 25, 22, 18, 8), hp: 340, rng: { mg: 1500 }, opt: 'day' });
put('rus_mrap_kamaz', { arm: A(18, 16, 14, 8, 20, 18, 15, 8), hp: 380, rng: { mg: 1500 }, opt: 'day' });
put('rus_mrap_vpk', { arm: A(22, 20, 16, 8, 25, 22, 18, 8), hp: 400, rng: { mg: 1500 }, opt: 'day' });
// hafif
put('rus_lv_tigr', { arm: A(15, 12, 10, 6, 15, 12, 10, 6), hp: 230, rng: { mg: 1500 }, opt: 'day' });
put('rus_lv_tigrm', { arm: A(18, 14, 12, 6, 18, 14, 12, 6), hp: 250, rng: { mg: 1500 }, opt: 'th' });
put('rus_lv_strela', { arm: A(15, 12, 10, 6, 15, 12, 10, 6), hp: 220, rng: { aa: 5000 }, opt: 'day' });
put('rus_lv_patriot', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 100, rng: {}, opt: 'eye' });
put('rus_lv_hunter', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 110, rng: { mg: 1000 }, opt: 'eye' });
put('rus_lv_ural', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 180, rng: {}, opt: 'eye' });
// saldırı helikopterleri: Vikhr 10000, Ataka 6000, 30 mm 2A42 (Ka-52/Mi-28) 2000-4000, S-8 roket 4000
put('rus_heli_ka52', { arm: A(25, 15, 10, 8, 25, 15, 10, 8), hp: 680, rng: { atgm: 10000, auto: 3000, rkt: 4000 }, opt: 'th3' });
put('rus_heli_mi28', { arm: A(30, 18, 12, 8, 30, 18, 12, 8), hp: 700, rng: { atgm: 6000, auto: 3000, rkt: 4000 }, opt: 'th3', radar: 8000 });
put('rus_heli_mi24', { arm: A(25, 15, 10, 8, 25, 15, 10, 8), hp: 720, rng: { atgm: 5000, auto: 2000, rkt: 4000 }, opt: 'day' });
put('rus_heli_mi35', { arm: A(25, 15, 10, 8, 25, 15, 10, 8), hp: 740, rng: { atgm: 6000, auto: 2000, rkt: 4000 }, opt: 'th' });
put('rus_heli_ka52m', { arm: A(25, 15, 10, 8, 25, 15, 10, 8), hp: 700, rng: { atgm: 15000, auto: 3000, rkt: 4000 }, opt: 'th3', radar: 10000 });
put('rus_heli_mi28n', { arm: A(30, 18, 12, 8, 30, 18, 12, 8), hp: 680, rng: { atgm: 6000, auto: 3000, rkt: 4000 }, opt: 'th3' });
// nakliye
put('rus_heli_mi8amtsh', { arm: A(15, 10, 8, 6, 15, 10, 8, 6), hp: 620, rng: { mg: 1500, rkt: 4000 }, opt: 'th' });
put('rus_heli_mi8', { arm: A(12, 8, 6, 4, 12, 8, 6, 4), hp: 560, rng: { mg: 1500 }, opt: 'day' });
put('rus_heli_mi17', { arm: A(12, 8, 6, 4, 12, 8, 6, 4), hp: 560, rng: { mg: 1500 }, opt: 'day' });
put('rus_heli_mi26', { arm: A(12, 8, 6, 4, 12, 8, 6, 4), hp: 900, rng: {}, opt: 'day' });
put('rus_heli_ka226', { arm: A(4, 4, 4, 2, 4, 4, 4, 2), hp: 300, rng: {}, opt: 'day' });
put('rus_heli_ansat', { arm: A(4, 4, 4, 2, 4, 4, 4, 2), hp: 300, rng: {}, opt: 'day' });
// İHA
put('rus_uav_orlan10', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 70, rng: {}, opt: 'uav', recon: true });
put('rus_uav_orlan30', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 90, rng: {}, opt: 'uav', recon: true });
put('rus_uav_zala42116e', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 60, rng: {}, opt: 'uav', recon: true });
put('rus_uav_eleron3', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 40, rng: {}, opt: 'uav' });
put('rus_uav_forpostr', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 180, rng: { atgm: 6000 }, opt: 'uav', recon: true });
put('rus_uav_orion', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 200, rng: { atgm: 8000 }, opt: 'uav' });

// kıyı / deniz piyadesi
put('usa_cst_nmesis', { arm: A(20, 18, 14, 8, 22, 20, 15, 8), hp: 260, rng: { ind: 185000 }, opt: 'th' });
put('usa_cst_lavm', { arm: A(30, 20, 15, 10, 30, 20, 15, 10), hp: 380, rng: { ind: 5935, mg: 1100 }, opt: 'day' });
put('usa_cst_lavad', { arm: A(30, 20, 15, 10, 30, 20, 15, 10), hp: 380, rng: { aa: 4800, auto: 2000 }, opt: 'th', radar: 10000 });
put('usa_cst_acvc', { arm: A(45, 30, 25, 15, 70, 50, 30, 15), hp: 480, rng: { mg: 1800 }, opt: 'th' });
put('usa_cst_mhimars', { arm: A(12, 10, 10, 6, 12, 10, 10, 6), hp: 300, rng: { ind: 70000 }, opt: 'eye' });
put('usa_cst_nsm', { arm: A(8, 6, 6, 4, 8, 6, 6, 4), hp: 260, rng: { ind: 185000 }, opt: 'eye' });
// dolanan mühimmat (fly: uçuş menzili)
put('usa_lm_sw300', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 12, rng: { fly: 10000 }, opt: 'uav' });
put('usa_lm_sw600', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 30, rng: { fly: 40000 }, opt: 'uav' });
put('usa_lm_alt600', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 40, rng: { fly: 440000 }, opt: 'uav' });
put('usa_lm_alt700', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 50, rng: { fly: 440000 }, opt: 'uav' });
put('usa_lm_bolt', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 18, rng: { fly: 20000 }, opt: 'uav' });
put('usa_lm_red', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 60, rng: { fly: 400000 }, opt: 'uav' });
put('rus_lm_lancet3', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 25, rng: { fly: 40000 }, opt: 'uav' });
put('rus_lm_lancet3m', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 28, rng: { fly: 70000 }, opt: 'uav' });
put('rus_lm_kub', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 25, rng: { fly: 40000 }, opt: 'uav' });
put('rus_lm_geran2', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 60, rng: { fly: 1500000 }, opt: 'uav' });
put('rus_lm_molniya2', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 25, rng: { fly: 20000 }, opt: 'uav' });
put('rus_lm_upyr', { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 22, rng: { fly: 10000 }, opt: 'uav' });

// ---------------------------------------------------------------- taban tipler (katalog dışı / girişi olmayan)
const BASE = {
	tank: { arm: A(560, 80, 40, 30, 950, 250, 60, 30), hp: 900, rng: { main: 3000, mg: 1500 }, opt: 'th' },
	apc: { arm: A(25, 18, 14, 8, 30, 20, 15, 8), hp: 450, rng: { mg: 1800 }, opt: 'day' },
	technical: { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 170, rng: { mg: 1800 }, opt: 'eye' },
	heli: { arm: A(25, 15, 10, 8, 25, 15, 10, 8), hp: 650, rng: { atgm: 8000, auto: 3000, rkt: 6000 }, opt: 'th3' },
	ifv: { arm: A(60, 30, 20, 12, 80, 40, 20, 12), hp: 620, rng: { auto: 2000, atgm: 4000, mg: 1100 }, opt: 'th' },
	aa: { arm: A(25, 18, 14, 8, 30, 20, 15, 8), hp: 480, rng: { aa: 8000, auto: 4000 }, opt: 'rad', radar: 18000 },
	arty: { arm: A(30, 20, 15, 12, 30, 20, 15, 12), hp: 420, rng: { ind: 24000, mg: 1500 }, opt: 'day' },
	transport: { arm: A(15, 10, 8, 6, 15, 10, 8, 6), hp: 520, rng: { mg: 1100 }, opt: 'th' },
	uav: { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 120, rng: {}, opt: 'uav' },
	uav_armed: { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 180, rng: { atgm: 8000 }, opt: 'uav' },
	loiter: { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 30, rng: {}, opt: 'uav' },
	fpv: { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 22, rng: {}, opt: 'uav' },
	fieldgun: { arm: A(6, 0, 0, 0, 6, 0, 0, 0), hp: 360, rng: { main: 2000, ind: 15000 }, opt: 'eye' },
	howitzer: { arm: A(6, 0, 0, 0, 6, 0, 0, 0), hp: 380, rng: { ind: 24000 }, opt: 'eye' },
	atgun: { arm: A(6, 0, 0, 0, 6, 0, 0, 0), hp: 300, rng: { main: 2000 }, opt: 'day' },
	aagun: { arm: A(6, 0, 0, 0, 6, 0, 0, 0), hp: 260, rng: { aa: 2500, auto: 2000 }, opt: 'eye' },
	hmortar: { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 200, rng: { ind: 7200 }, opt: 'eye' },
	mtngun: { arm: A(5, 0, 0, 0, 5, 0, 0, 0), hp: 240, rng: { ind: 11000, main: 1500 }, opt: 'eye' },
	mlrs: { arm: A(8, 6, 6, 4, 8, 6, 6, 4), hp: 320, rng: { ind: 20000 }, opt: 'eye' },
	truck: { arm: A(0, 0, 0, 0, 0, 0, 0, 0), hp: 160, rng: {}, opt: 'eye' },
};

// piyade silahları (etkili menzil, m) ve optik
// rng: el silahı / roket etkili menzili; rng_<ulus>: ulusa özel (M249 800 / PKP 1000, M110 800 / SV-98 1000,
// AT4 300 / RPG-7V2 400, Javelin 2500 / Kornet 5500); ind: dolaylı atış (havan 60 mm 3490 / 82 mm 4270, FPV kumanda 5000)
const INF = {
	rifle: { rng: 500, opt: 'eye' }, leader: { rng: 500, opt: 'bino' },
	mg: { rng: 1000, rng_usa: 800, rng_rus: 1000, opt: 'eye' },
	sniper: { rng: 1000, rng_usa: 800, rng_rus: 1000, opt: 'scope' },
	at: { rng: 300, rng_usa: 300, rng_rus: 400, opt: 'eye' },
	atgm: { rng: 2500, rng_usa: 2500, rng_rus: 5500, opt: 'cl' },
	engineer: { rng: 400, opt: 'eye' },
	mortar: { rng: 400, ind_usa: 3490, ind_rus: 4270, opt: 'eye' },
	drone: { rng: 300, ind: 5000, opt: 'eye' },
	crew: { rng: 300, opt: 'eye' }, medic: { rng: 300, opt: 'eye' },
};

const out = {
	note: 'Gerçek savaş verisi (roadmap 49/50/51) — açık kaynak tahminleri, yaklaşık. arm: [[kinetik ön, yan, arka, üst], [HEAT ön, yan, arka, üst]] mm RHA eşdeğeri (oyunda ÷20 zırh birimi). hp: dayanıklılık. rng: silah başına gerçek etkili menzil (m) — main ana top, atgm güdümlü füze, auto otomatik top, mg makineli, rkt roket, aa havadaki hedef, ind dolaylı atış azami menzili. Oyun menzili = gerçek × K_range (dolaylı atış harita köşegeniyle sınırlı). opt: optik sınıfı (tespit çarpanı). radar: hava hedefi algılama (m). aps: aktif koruma, slat: kafes zırh (RPG etkisi azalır), recon: keşif aracı.',
	K_range: 1.0,
	K_detect: 1.0,
	det_base: 2200,
	optics: { eye: 1.0, bino: 1.3, day: 1.4, scope: 1.6, cl: 2.0, th: 2.0, th3: 2.4, uav: 2.6, rad: 1.4 },
	base: BASE,
	inf: INF,
	units: U,
};
fs.writeFileSync(process.argv[2], JSON.stringify(out, null, 1));
console.log('units', Object.keys(U).length);

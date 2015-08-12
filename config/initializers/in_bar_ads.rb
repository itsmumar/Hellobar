# Site.where("script_installed_at IS NOT NULL AND script_uninstalled_at IS NULL").order("created_at DESC").limit(1000).pluck(:id)
site_ids = [220452, 220444, 220430, 220427, 220425, 220423, 220421, 220420, 220409, 220401, 220400, 220399, 220396, 220395, 220393, 220391, 220387, 220385, 220384, 220383, 220382, 220381, 220380, 220378, 220376, 220375, 220374, 220372, 220370, 220361, 220353, 220352, 220338, 220337, 220335, 220326, 220323, 220320, 220316, 220314, 220297, 220291, 220290, 220288, 220285, 220265, 220260, 220259, 220254, 220253, 220251, 220248, 220247, 220246, 220237, 220235, 220229, 220223, 220221, 220213, 220207, 220205, 220202, 220201, 220200, 220198, 220197, 220181, 220179, 220177, 220175, 220174, 220170, 220169, 220163, 220162, 220161, 220160, 220158, 220156, 220154, 220152, 220149, 220148, 220143, 220139, 220132, 220129, 220128, 220119, 220118, 220110, 220107, 220106, 220100, 220098, 220085, 220083, 220082, 220079, 220076, 220074, 220073, 220072, 220070, 220069, 220060, 220057, 220055, 220054, 220046, 220044, 220038, 220033, 220032, 220029, 220024, 220021, 220020, 220019, 220014, 220013, 220008, 220005, 220001, 219991, 219983, 219981, 219976, 219972, 219967, 219965, 219963, 219961, 219960, 219955, 219951, 219950, 219946, 219940, 219939, 219935, 219933, 219932, 219931, 219920, 219919, 219912, 219894, 219892, 219890, 219889, 219886, 219882, 219879, 219875, 219874, 219873, 219868, 219865, 219863, 219862, 219856, 219854, 219851, 219844, 219843, 219842, 219840, 219836, 219834, 219831, 219830, 219828, 219827, 219816, 219814, 219810, 219807, 219805, 219804, 219801, 219800, 219797, 219795, 219791, 219784, 219782, 219781, 219780, 219777, 219772, 219771, 219770, 219769, 219768, 219765, 219764, 219762, 219761, 219755, 219748, 219747, 219746, 219736, 219735, 219729, 219728, 219724, 219721, 219719, 219718, 219704, 219703, 219701, 219700, 219698, 219695, 219690, 219689, 219687, 219683, 219682, 219680, 219676, 219668, 219665, 219661, 219659, 219657, 219652, 219647, 219633, 219631, 219630, 219628, 219627, 219622, 219617, 219615, 219607, 219606, 219604, 219603, 219600, 219598, 219592, 219591, 219588, 219586, 219581, 219576, 219573, 219570, 219569, 219561, 219558, 219557, 219555, 219554, 219552, 219546, 219540, 219539, 219538, 219536, 219535, 219532, 219530, 219529, 219524, 219523, 219522, 219519, 219511, 219508, 219507, 219491, 219490, 219482, 219481, 219478, 219475, 219474, 219473, 219471, 219469, 219468, 219467, 219466, 219464, 219463, 219462, 219461, 219458, 219448, 219446, 219434, 219428, 219422, 219420, 219415, 219414, 219410, 219409, 219407, 219406, 219402, 219401, 219399, 219392, 219391, 219388, 219384, 219379, 219377, 219362, 219360, 219357, 219351, 219348, 219345, 219344, 219340, 219337, 219334, 219333, 219330, 219328, 219325, 219324, 219322, 219321, 219320, 219319, 219317, 219316, 219306, 219305, 219304, 219295, 219292, 219291, 219290, 219288, 219287, 219285, 219283, 219280, 219279, 219273, 219267, 219266, 219265, 219264, 219263, 219261, 219257, 219256, 219254, 219253, 219252, 219251, 219249, 219247, 219246, 219243, 219239, 219237, 219234, 219233, 219232, 219229, 219228, 219223, 219222, 219221, 219219, 219218, 219216, 219215, 219214, 219210, 219208, 219207, 219206, 219204, 219199, 219198, 219196, 219195, 219191, 219188, 219185, 219184, 219171, 219170, 219156, 219155, 219151, 219150, 219149, 219147, 219144, 219143, 219138, 219137, 219133, 219126, 219122, 219118, 219117, 219111, 219110, 219109, 219108, 219105, 219103, 219094, 219092, 219086, 219082, 219080, 219079, 219077, 219076, 219075, 219074, 219073, 219071, 219070, 219069, 219068, 219065, 219063, 219059, 219050, 219047, 219045, 219044, 219040, 219034, 219033, 219031, 219030, 219025, 219023, 219022, 219019, 219016, 219014, 219013, 219010, 219009, 219007, 219006, 219005, 218999, 218998, 218990, 218988, 218981, 218980, 218976, 218975, 218969, 218967, 218965, 218954, 218952, 218949, 218946, 218945, 218943, 218941, 218939, 218937, 218933, 218932, 218931, 218921, 218918, 218913, 218912, 218908, 218900, 218898, 218897, 218896, 218893, 218892, 218891, 218889, 218888, 218885, 218883, 218880, 218875, 218873, 218872, 218870, 218869, 218868, 218867, 218866, 218865, 218861, 218860, 218859, 218855, 218848, 218847, 218844, 218842, 218838, 218836, 218834, 218829, 218827, 218825, 218824, 218823, 218821, 218817, 218815, 218813, 218811, 218810, 218809, 218808, 218806, 218805, 218802, 218801, 218800, 218795, 218794, 218793, 218792, 218789, 218788, 218787, 218786, 218784, 218781, 218778, 218775, 218774, 218773, 218772, 218770, 218766, 218760, 218751, 218749, 218742, 218739, 218738, 218731, 218723, 218722, 218717, 218710, 218706, 218705, 218703, 218700, 218699, 218698, 218697, 218694, 218685, 218684, 218681, 218674, 218673, 218671, 218668, 218621, 218620, 218618, 218612, 218611, 218609, 218599, 218597, 218593, 218591, 218590, 218585, 218578, 218573, 218572, 218571, 218566, 218565, 218563, 218559, 218558, 218556, 218555, 218552, 218551, 218545, 218544, 218539, 218532, 218529, 218526, 218524, 218521, 218520, 218518, 218517, 218516, 218511, 218510, 218509, 218504, 218503, 218500, 218499, 218498, 218494, 218493, 218492, 218491, 218490, 218489, 218486, 218483, 218481, 218472, 218470, 218467, 218465, 218464, 218463, 218459, 218457, 218456, 218454, 218451, 218443, 218442, 218437, 218423, 218422, 218420, 218416, 218414, 218412, 218411, 218409, 218408, 218402, 218392, 218387, 218385, 218381, 218377, 218374, 218372, 218370, 218367, 218366, 218358, 218357, 218356, 218352, 218349, 218347, 218344, 218332, 218331, 218330, 218329, 218323, 218317, 218310, 218307, 218306, 218304, 218298, 218296, 218294, 218280, 218278, 218275, 218271, 218270, 218267, 218265, 218263, 218258, 218252, 218251, 218248, 218246, 218245, 218242, 218240, 218237, 218233, 218232, 218229, 218228, 218226, 218223, 218221, 218218, 218216, 218202, 218201, 218200, 218194, 218191, 218189, 218178, 218177, 218170, 218169, 218168, 218166, 218164, 218162, 218161, 218160, 218156, 218153, 218151, 218150, 218145, 218138, 218137, 218130, 218128, 218127, 218120, 218118, 218117, 218114, 218112, 218110, 218102, 218092, 218088, 218087, 218080, 218079, 218077, 218065, 218063, 218057, 218055, 218053, 218051, 218048, 218047, 218046, 218036, 218033, 218031, 218029, 218020, 218017, 218013, 218012, 218008, 218001, 218000, 217999, 217990, 217986, 217981, 217980, 217971, 217968, 217964, 217962, 217959, 217957, 217955, 217954, 217953, 217947, 217943, 217941, 217938, 217920, 217910, 217908, 217907, 217894, 217892, 217889, 217885, 217884, 217882, 217881, 217875, 217874, 217870, 217869, 217868, 217867, 217865, 217862, 217858, 217857, 217855, 217852, 217850, 217846, 217843, 217839, 217838, 217837, 217836, 217834, 217828, 217823, 217819, 217810, 217809, 217806, 217801, 217800, 217799, 217796, 217793, 217788, 217786, 217783, 217782, 217781, 217775, 217771, 217767, 217766, 217759, 217754, 217740, 217734, 217733, 217730, 217727, 217723, 217722, 217715, 217712, 217711, 217707, 217704, 217701, 217698, 217692, 217686, 217680, 217668, 217667, 217664, 217657, 217656, 217646, 217644, 217637, 217636, 217635, 217632, 217625, 217624, 217620, 217616, 217615, 217605, 217604, 217602, 217600, 217597, 217596, 217594, 217592, 217590, 217588, 217583, 217581, 217580, 217577, 217571, 217566, 217561, 217550, 217547, 217546, 217544, 217542, 217541, 217539, 217533, 217528, 217526, 217525, 217524, 217522, 217520, 217519, 217512, 217506, 217503, 217499, 217497, 217496, 217494, 217493, 217488, 217484, 217483, 217482, 217480, 217478, 217476, 217470, 217469, 217468, 217464, 217463, 217462, 217459, 217458, 217456, 217455, 217454, 217448, 217446, 217445, 217443, 217441, 217436, 217427, 217420, 217419, 217418, 217417, 217416, 217414, 217412, 217409, 217408, 217405, 217401, 217399, 217398, 217394, 217390, 217382, 217380, 217371, 217366, 217364, 217359, 217356, 217350, 217335, 217333, 217331, 217329, 217327, 217326, 217324, 217323, 217322, 217317, 217315, 217308, 217306, 217305, 217304, 217302, 217298, 217297, 217293, 217292, 217291, 217289, 217288, 217286, 217285, 217284, 217283, 217282, 217281, 217277, 217275, 217273, 217272, 217271, 217269, 217266, 217261]
site_ids = Set.new(site_ids)

if %x[hostname].strip == 'edge.hellobar.com'
  Site.in_bar_ads_config = {
    test_fraction: 1.0,
    show_to_fraction: 0.9
  }
elsif Rails.env.production?
  Site.in_bar_ads_config = {
    site_ids: site_ids
  }
end
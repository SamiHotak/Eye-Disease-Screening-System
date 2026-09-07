/// Reference text for every label in the unified disease set produced by
/// preprocess.py. Lookup is tolerant of underscores, case and spacing, so it
/// still resolves if the exported labels.txt is reordered or trimmed.
class ConditionInfo {
  final String display;
  final String summary;

  const ConditionInfo(this.display, this.summary);

  static const ConditionInfo unknown = ConditionInfo(
    'Unrecognised finding',
    'This label is not in the reference library. It came from the model\'s '
        'labels.txt, so the app still reports its score.',
  );

  static const Map<String, ConditionInfo> _byKey = {
    'normal': ConditionInfo(
      'Normal',
      'No disease pattern detected. The retina appears within normal limits '
          'for the features this model was trained on.',
    ),
    'diabeticretinopathy': ConditionInfo(
      'Diabetic Retinopathy',
      'Damage to retinal blood vessels caused by long-standing diabetes. '
          'Appears as microaneurysms, haemorrhages and exudates. A leading '
          'cause of preventable blindness in working-age adults.',
    ),
    'glaucoma': ConditionInfo(
      'Glaucoma',
      'Progressive damage to the optic nerve, usually linked to raised '
          'pressure inside the eye. On a fundus photo it shows as an enlarged '
          'cup-to-disc ratio. Vision loss from glaucoma is irreversible.',
    ),
    'amd': ConditionInfo(
      'Age-related Macular Degeneration',
      'Deterioration of the macula, the central part of the retina. Causes '
          'loss of sharp central vision while peripheral vision is preserved.',
    ),
    'cataract': ConditionInfo(
      'Cataract',
      'Clouding of the natural lens. On a fundus image it appears as a hazy, '
          'washed-out view because light cannot pass cleanly to the retina.',
    ),
    'hypertensiveretinopathy': ConditionInfo(
      'Hypertensive Retinopathy',
      'Retinal vessel changes caused by chronic high blood pressure, '
          'including arteriolar narrowing, nicking and flame-shaped '
          'haemorrhages.',
    ),
    'pathologicalmyopia': ConditionInfo(
      'Pathological Myopia',
      'Severe near-sightedness with structural stretching of the eyeball, '
          'producing a tilted disc, peripapillary atrophy and thinned retina.',
    ),
    'mediahaze': ConditionInfo(
      'Media Haze',
      'Reduced clarity of the ocular media, so the retinal image looks blurred '
          'or veiled. Often caused by cataract or vitreous opacity.',
    ),
    'drusen': ConditionInfo(
      'Drusen',
      'Yellow deposits beneath the retina. Small amounts are common with age; '
          'larger or numerous drusen are an early marker of macular '
          'degeneration.',
    ),
    'tessellation': ConditionInfo(
      'Tessellation',
      'A tigroid or chequered fundus appearance where large choroidal vessels '
          'show through a thin retinal pigment layer. Common in myopic eyes.',
    ),
    'epiretinalmembrane': ConditionInfo(
      'Epiretinal Membrane',
      'A thin fibrous sheet growing on the retinal surface. It can contract '
          'and wrinkle the macula, distorting straight lines in vision.',
    ),
    'branchretinalveinocclusion': ConditionInfo(
      'Branch Retinal Vein Occlusion',
      'Blockage of one branch of the retinal venous system, producing '
          'wedge-shaped haemorrhages along the affected vein.',
    ),
    'centralretinalveinocclusion': ConditionInfo(
      'Central Retinal Vein Occlusion',
      'Blockage of the main retinal vein, causing widespread haemorrhages '
          'across all four quadrants and a swollen optic disc.',
    ),
    'centralserousretinopathy': ConditionInfo(
      'Central Serous Retinopathy',
      'Fluid collecting under the macula, lifting the retina and blurring or '
          'dimming central vision. Often associated with stress.',
    ),
    'opticdisccupping': ConditionInfo(
      'Optic Disc Cupping',
      'An enlarged hollow at the centre of the optic disc, indicating loss of '
          'nerve fibres. The principal structural sign of glaucoma.',
    ),
    'opticdiscpallor': ConditionInfo(
      'Optic Disc Pallor',
      'Abnormal paleness of the optic disc, reflecting atrophy of the optic '
          'nerve from prior damage, compression or poor blood supply.',
    ),
    'opticdiscedema': ConditionInfo(
      'Optic Disc Edema',
      'Swelling of the optic disc with blurred margins. May signal raised '
          'intracranial pressure and warrants urgent assessment.',
    ),
    'laserscars': ConditionInfo(
      'Laser Scars',
      'Round pigmented marks left by previous laser photocoagulation. '
          'Evidence of past treatment rather than active disease.',
    ),
    'macularscar': ConditionInfo(
      'Macular Scar',
      'Fibrous scarring at the macula from earlier inflammation, bleeding or '
          'infection, causing permanent loss of central detail.',
    ),
    'exudation': ConditionInfo(
      'Exudation',
      'Hard exudates: yellow lipid and protein deposits leaking from damaged '
          'vessels. Frequently seen in diabetic and hypertensive retinopathy.',
    ),
    'cottonwoolspots': ConditionInfo(
      'Cotton Wool Spots',
      'Fluffy white patches marking small areas of nerve fibre layer that '
          'lost their blood supply. A sign of vascular disease.',
    ),
    'retinitis': ConditionInfo(
      'Retinitis',
      'Inflammation of the retina, usually infectious, producing whitened '
          'retinal patches with associated haemorrhage.',
    ),
    'retinitispigmentosa': ConditionInfo(
      'Retinitis Pigmentosa',
      'An inherited degeneration of the light-sensing cells, marked by '
          'bone-spicule pigment, attenuated vessels and a waxy pale disc.',
    ),
    'otherabnormality': ConditionInfo(
      'Other Abnormality',
      'A catch-all for findings that are abnormal but too uncommon in the '
          'training data to be given their own class. Treat it as "something '
          'is off, look closer" rather than a specific diagnosis.',
    ),
  };

  static String _key(String raw) =>
      raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static ConditionInfo lookup(String label) => _byKey[_key(label)] ?? unknown;

  /// Falls back to a tidied version of the raw label when it is not in the map.
  static String displayName(String label) {
    final hit = _byKey[_key(label)];
    if (hit != null) return hit.display;
    return label
        .split(RegExp(r'[_\s]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }
}

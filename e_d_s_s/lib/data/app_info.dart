/// Every piece of app-identity and developer text lives here, exactly like
/// PDDS's app_info.dart. Edit this one file and all three screens follow.
class AppInfo {
  // ---------------------------------------------------------------- identity

  static const String name = 'OSS';
  static const String fullName = 'Ocular Screening System';
  static const String tagline = fullName;
  static const String version = '1.0.0';

  static const String description =
      'OSS stands for Ocular Screening System. It screens a retinal fundus '
      'photograph for signs of multiple eye diseases at once. The neural '
      'network runs entirely on your device, so it works with no internet '
      'connection and no image ever leaves your phone.';

  // ------------------------------------------------------------- how it works
  static const String modelSummary =
      'An EfficientNetV2-S convolutional network with a multi-label sigmoid '
      'head. Unlike a single-answer classifier, it scores every condition '
      'independently, so one image can show several findings at the same time '
      'or none at all.';

  static const String preprocessingSummary =
      'Each photo is cropped to the circular fundus area, white-balanced with '
      'a grey-world correction, contrast-equalised with CLAHE in LAB colour '
      'space, then resized. This is the identical preparation used during '
      'training, which is what keeps on-device accuracy close to laboratory '
      'accuracy.';

  // ------------------------------------------------------ TODO: your numbers
  // Replace these with the values printed by the metrics cell in the notebook.
  static const String trainingData =
      'RFMiD (3,200 images, 45 expert-annotated conditions) combined with '
      'ODIR-5K (6,392 images, 8 coarse classes). Labels from both sources were '
      'harmonised onto one unified disease set.';
  static const String macroAuc = '0.85';
  static const String meanAveragePrecision = '0.57';
  static const String macroF1 = '0.59';

  // --------------------------------------------------------------- developer
  static const String developerPhoto = 'assets/images/developer.jpg';
  static const String developerName = 'Sami Hotak';
  static const String developerRole = 'Deep Learning Engineer';
  static const String developerInstitution = 'Ghalib University';
  static const String developerEmail = 'samiullahhotak2002@gmail.com';
  static const String developerPhone = '+93 777724870';
  static const String developerWebsite = 'https://example.com';
  static const String supervisor = '';

  static const String projectNote =
      'Built as an end-to-end machine learning project: dataset harmonisation '
      'and model training in Python and TensorFlow, quantised to TensorFlow '
      'Lite, deployed in this Flutter application for offline inference.';

  // ------------------------------------------------------------- disclaimer
  static const String disclaimerShort =
      'Screening aid only. Not a medical diagnosis.';

  static const String disclaimerLong =
      'This application is a student research project, not a medical device. '
      'It has not been clinically validated or approved by any regulatory '
      'body. Its output is a statistical estimate from image patterns and can '
      'be wrong in both directions: it may flag a healthy eye, and it may miss '
      'real disease. Never use it to make a treatment decision, to reassure '
      'yourself, or to delay care. Any concern about your eyes or vision '
      'belongs with a qualified ophthalmologist or optometrist.';
}

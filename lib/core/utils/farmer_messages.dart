class FarmerMessages {
  static String getWelcome(bool isChichewa) {
    if (isChichewa) {
      return 'Takulandirani ku MbewuSmart!\nTipezeni thanki kuti muli pano.';
    }
    return 'Welcome to MbewuSmart!\nThank you for being here.';
  }

  static String getConfidenceLow(bool isChichewa) {
    if (isChichewa) {
      return 'Tikukayikira pang\'ono. Izi sizinthu zatsopano kwa ife. Chonde funsani Afesa Officer yanu kuti athe kuthandizani.';
    }
    return 'We are not very sure. This is new for us. Please ask your Extension Officer to help.';
  }

  static String getConfidenceMedium(bool isChichewa) {
    if (isChichewa) {
      return 'Tili ndi chidwi pang\'ono. Chonde yang\'anani mbewu zanu nthawi zonse.';
    }
    return 'We are somewhat sure. Please keep monitoring your crops regularly.';
  }

  static String getConfidenceHigh(bool isChichewa) {
    if (isChichewa) {
      return 'Tili ndi chikhulupiriro chachikulu! Ichi ndi chomwe tikuona.';
    }
    return 'We are very confident! This is what we see.';
  }

  static String getUncertainResult(bool isChichewa) {
    if (isChichewa) {
      return '''Ndani Yotayika!
 
Tikumanapo ndi zinthu zosayenera. Izi sizithetsa kuti tikhale ndi chikhulupiriro.

CHOMWE MUNGACHITE:
- Tengani photho lina la mbewu yanu
- Funsani abale anu ogula mphesa
- Funsani Afesa Officer yanu

TIPHUNZIRE: Kuthana ndi zovuta zambiri, kuyamba kale ndi bwino.'''
      ;
    }
    return '''Uncertain Result!

We found something that doesn't quite match. This means we cannot be confident.

WHAT YOU CAN DO:
- Take another photo of your crop
- Ask fellow farmers
- Contact your Extension Officer

TIP: Starting early helps solve many problems.''';
  }

  static String getNeedHelp(bool isChichewa) {
    if (isChichewa) {
      return 'Mukufuna Thandizo?';
    }
    return 'Need Help?';
  }

  static String getContactOfficer(bool isChichewa) {
    if (isChichewa) {
      return 'Lankhulani ndi Afesa';
    }
    return 'Contact Officer';
  }

  static String getContactDealer(bool isChichewa) {
    if (isChichewa) {
      return 'Lankhulani ndi Agro-Dealer';
    }
    return 'Contact Agro-Dealer';
  }

  static String getHealthyCrop(bool isChichewa) {
    if (isChichewa) {
      return 'Mbewu Yauchipuka!';
    }
    return 'Healthy Crop!';
  }

  static String getDiseaseFound(bool isChichewa) {
    if (isChichewa) {
      return 'Tapeza Matenda';
    }
    return 'Disease Found';
  }

  static String getPestFound(bool isChichewa) {
    if (isChichewa) {
      return 'Tapeza Khumani';
    }
    return 'Pest Found';
  }

  static String getDeficiencyFound(bool isChichewa) {
    if (isChichewa) {
      return 'Vuto la Chakudya';
    }
    return 'Nutrient Problem';
  }

  static String getTreatmentAvailable(bool isChichewa) {
    if (isChichewa) {
      return 'Mulingo Ulipo';
    }
    return 'Treatment Available';
  }

  static String getNoTreatment(bool isChichewa) {
    if (isChichewa) {
      return 'Palibe Mulingo';
    }
    return 'No Treatment';
  }

  static String getPrevention(bool isChichewa) {
    if (isChichewa) {
      return 'Kuteteza';
    }
    return 'Prevention';
  }

  static String getTreatment(bool isChichewa) {
    if (isChichewa) {
      return 'Mulingo';
    }
    return 'Treatment';
  }

  static String getNextSteps(bool isChichewa) {
    if (isChichewa) {
      return 'Zochitika Zotsatira';
    }
    return 'Next Steps';
  }

  static String getImmediateAction(bool isChichewa) {
    if (isChichewa) {
      return 'CHITANI IZI NZGOGO:';
    }
    return 'DO THIS NOW:';
  }

  static String getMonitoringAdvice(bool isChichewa) {
    if (isChichewa) {
      return 'Yang\'anani mbewu zanu masiku 2-3. Ngati zikwiya, pitani ku Agro-Dealer yanu.';
    }
    return 'Check your crops every 2-3 days. If it gets worse, visit your Agro-Dealer.';
  }

  static String getSuccessMessage(bool isChichewa) {
    if (isChichewa) {
      return 'Wachita bwino! Mbewu yanu ili yauchipuka.';
    }
    return 'Well done! Your crop is healthy.';
  }

  static String getActionNeededMessage(bool isChichewa) {
    if (isChichewa) {
      return 'Pali zomwe muyenera kuchita. Onani pasi papezako chisangalatsi.';
    }
    return 'There is something you need to do. See below for important actions.';
  }

  static String getEmergencyMessage(bool isChichewa) {
    if (isChichewa) {
      return 'ZOYENERA KWANU! Chonde chitani cisangalatsi nthawi yambiri.';
    }
    return 'IMPORTANT! Please act quickly.';
  }

  static String getExtensionOfficerNearby(bool isChichewa) {
    if (isChichewa) {
      return 'Afesa Officer yanu ili pafupi. Munga lankhule kuti athandize.';
    }
    return 'Your Extension Officer is nearby. Call them for help.';
  }

  static String getAgroDealerNearby(bool isChichewa) {
    if (isChichewa) {
      return 'Agro-Dealer yanu ili pafupi. Munga lankhule kuti agule mulingo.';
    }
    return 'Your Agro-Dealer is nearby. Call them to get medicine.';
  }

  static String getCallNow(bool isChichewa) {
    if (isChichewa) {
      return 'Lankhulani';
    }
    return 'Call Now';
  }

  static String getGetDirections(bool isChichewa) {
    if (isChichewa) {
      return 'Pita';
    }
    return 'Go There';
  }

  static String getSaveDiagnosis(bool isChichewa) {
    if (isChichewa) {
      return 'Sungani';
    }
    return 'Save';
  }

  static String getTryAgain(bool isChichewa) {
    if (isChichewa) {
      return 'Yang\'ananso';
    }
    return 'Try Again';
  }

  static String getShareResult(bool isChichewa) {
    if (isChichewa) {
      return 'Gawani';
    }
    return 'Share';
  }
}

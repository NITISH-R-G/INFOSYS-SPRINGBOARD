/// Contract model for the app
class Contract {
  final String id;
  final String userId;
  final String? dealerId;
  final String title;
  final String? filePath;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ContractAnalysis? analysis;
  final VinLookupResult? vinLookup;

  Contract({
    required this.id,
    required this.userId,
    this.dealerId,
    required this.title,
    this.filePath,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.analysis,
    this.vinLookup,
  });

  factory Contract.fromJson(Map<String, dynamic> json) {
    // Backend returns flat structure, not nested 'analysis' object
    // Build ContractAnalysis from flat fields if fairness_score exists
    ContractAnalysis? analysis;

    // Check if we have structured_json (from SQLite) or flat fields (from API)
    if (json['structured_json'] != null) {
      // TODO: Parse structured_json string to object if needed
    }

    // For now, support the existing flat structure used by the app logic
    if (json['fairness_score'] != null || json['sla_data'] != null) {
      analysis = ContractAnalysis(
        slaData: json['sla_data'] != null
            ? SlaData.fromJson(json['sla_data'])
            : null,
        fairnessScore: json['fairness_score'] ?? 0,
        fairnessExplanation: json['fairness_explanation'],
        redFlags:
            (json['red_flags'] as List<dynamic>?)
                ?.map((e) => RedFlag.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        confidenceScore: json['confidence_score'] ?? 0,
        contractType: json['contract_type'],
        detailedAnalysis: json['detailed_analysis'] != null
            ? DetailedAnalysis.fromJson(json['detailed_analysis'])
            : null,
      );
    }

    return Contract(
      id: json['id'].toString(), // Ensure String
      userId: json['user_id'] ?? '',
      dealerId: json['dealer_id'],
      title: json['title'] ?? json['filename'] ?? 'Untitled Contract',
      filePath: json['file_path'],
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      analysis: analysis,
      vinLookup: json['vin_lookup'] != null
          ? VinLookupResult.fromJson(json['vin_lookup'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'dealer_id': dealerId,
      'title': title,
      'file_path': filePath,
      'status': status,
      'fairness_score': analysis?.fairnessScore,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      // 'structured_json': ... // Serialize analysis to JSON string for DB
    };
  }
}

/// Contract Analysis result
class ContractAnalysis {
  final SlaData? slaData;
  final int fairnessScore;
  final String? fairnessExplanation;
  final List<RedFlag> redFlags;
  final int confidenceScore;
  final String? contractType;
  final DetailedAnalysis? detailedAnalysis;

  ContractAnalysis({
    this.slaData,
    required this.fairnessScore,
    this.fairnessExplanation,
    required this.redFlags,
    required this.confidenceScore,
    this.contractType,
    this.detailedAnalysis,
  });

  factory ContractAnalysis.fromJson(Map<String, dynamic> json) {
    return ContractAnalysis(
      slaData: json['sla_data'] != null
          ? SlaData.fromJson(json['sla_data'])
          : null,
      fairnessScore: json['fairness_score'] ?? 0,
      fairnessExplanation: json['fairness_explanation'],
      redFlags:
          (json['red_flags'] as List<dynamic>?)
              ?.map((e) => RedFlag.fromJson(e))
              .toList() ??
          [],
      confidenceScore: json['confidence_score'] ?? 0,
      contractType: json['contract_type'],
      detailedAnalysis: json['detailed_analysis'] != null
          ? DetailedAnalysis.fromJson(json['detailed_analysis'])
          : null,
    );
  }
}

/// SLA Data extracted from contract
class SlaData {
  final String currencyCode;
  final double? apr;
  final int? termMonths;
  final double? monthlyPayment;
  final double? downPayment;
  final double? residualValue;
  final int? mileageLimit;
  final double? mileageOverageFee;
  final String? earlyTerminationFee;
  final double? buyoutPrice;
  final bool? maintenanceIncluded;
  final int? warrantyMonths;
  final double? documentationFee;
  final double? acquisitionFee;
  final double? dispositionFee;
  final double? marketValue;
  final double? marketValueHigh;
  final double? marketValueLow;
  final String? marketConfidence;

  SlaData({
    this.currencyCode = 'INR',
    this.apr,
    this.termMonths,
    this.monthlyPayment,
    this.downPayment,
    this.residualValue,
    this.mileageLimit,
    this.mileageOverageFee,
    this.earlyTerminationFee,
    this.buyoutPrice,
    this.maintenanceIncluded,
    this.warrantyMonths,
    this.documentationFee,
    this.acquisitionFee,
    this.dispositionFee,
    this.marketValue,
    this.marketValueHigh,
    this.marketValueLow,
    this.marketConfidence,
  });

  factory SlaData.fromJson(Map<String, dynamic> json) {
    return SlaData(
      currencyCode: json['currency_code'] ?? 'INR',
      apr: (json['apr'] as num?)?.toDouble(),
      termMonths: json['term_months'],
      monthlyPayment: (json['monthly_payment'] as num?)?.toDouble(),
      downPayment: (json['down_payment'] as num?)?.toDouble(),
      residualValue: (json['residual_value'] as num?)?.toDouble(),
      mileageLimit: json['mileage_limit'],
      mileageOverageFee: (json['mileage_overage_fee'] as num?)?.toDouble(),
      earlyTerminationFee: json['early_termination_fee'],
      buyoutPrice: (json['buyout_price'] as num?)?.toDouble(),
      maintenanceIncluded: json['maintenance_included'],
      warrantyMonths: json['warranty_months'],
      documentationFee: (json['documentation_fee'] as num?)?.toDouble(),
      acquisitionFee: (json['acquisition_fee'] as num?)?.toDouble(),
      dispositionFee: (json['disposition_fee'] as num?)?.toDouble(),
      marketValue: (json['market_value'] as num?)?.toDouble(),
      marketValueHigh: (json['market_value_high'] as num?)?.toDouble(),
      marketValueLow: (json['market_value_low'] as num?)?.toDouble(),
      marketConfidence: json['market_confidence'],
    );
  }
}

/// Red Flag identified in contract
class RedFlag {
  final String clauseText;
  final String title;
  final String riskLevel;
  final String? whyFlag;
  final String? risks;
  final String? plainExplanation;
  final String? suggestion;

  RedFlag({
    required this.clauseText,
    required this.title,
    required this.riskLevel,
    this.whyFlag,
    this.risks,
    this.plainExplanation,
    this.suggestion,
  });

  factory RedFlag.fromJson(Map<String, dynamic> json) {
    return RedFlag(
      clauseText: json['clause_text'] ?? '',
      title: json['title'] ?? 'Unknown Issue',
      riskLevel: json['risk_level'] ?? 'medium',
      whyFlag: json['why_flag'],
      risks: json['risks'],
      plainExplanation: json['plain_explanation'],
      suggestion: json['suggestion'],
    );
  }
}

/// VIN Lookup result
class VehicleInfo {
  final String vin;
  final String? make;
  final String? model;
  final int? year;
  final String? bodyClass;
  final String? engineType;
  final String? fuelType;
  final String? driveType;
  final String? transmission;
  final List<VehicleRecall> recalls;

  // Pricing & Metadata
  final double? msrp;
  final double? marketAverage;
  final double? fairPriceLow;
  final double? fairPriceHigh;
  final List<String> incentives;
  final List<String> dataSources;
  final String? timestamp;
  final Map<String, dynamic>? confidenceIndicators;

  VehicleInfo({
    required this.vin,
    this.make,
    this.model,
    this.year,
    this.bodyClass,
    this.engineType,
    this.fuelType,
    this.driveType,
    this.transmission,
    this.recalls = const [],
    this.msrp,
    this.marketAverage,
    this.fairPriceLow,
    this.fairPriceHigh,
    this.incentives = const [],
    this.dataSources = const [],
    this.timestamp,
    this.confidenceIndicators,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      vin: json['vin'] ?? '',
      make: json['make'],
      model: json['model'],
      year: json['year'],
      bodyClass: json['body_class'],
      engineType: json['engine_type'],
      fuelType: json['fuel_type'],
      driveType: json['drive_type'],
      transmission: json['transmission'],
      recalls:
          (json['recalls'] as List<dynamic>?)
              ?.map((e) => VehicleRecall.fromJson(e))
              .toList() ??
          [],
      msrp: (json['msrp'] as num?)?.toDouble(),
      marketAverage: (json['market_average'] as num?)?.toDouble(),
      fairPriceLow: (json['fair_price_low'] as num?)?.toDouble(),
      fairPriceHigh: (json['fair_price_high'] as num?)?.toDouble(),
      incentives:
          (json['incentives'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      dataSources:
          (json['data_sources'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      timestamp: json['timestamp'],
      confidenceIndicators:
          json['confidence_indicators'] as Map<String, dynamic>?,
    );
  }
}

/// Vehicle Recall info
class VehicleRecall {
  final String component;
  final String summary;
  final String consequence;
  final String remedy;

  VehicleRecall({
    required this.component,
    required this.summary,
    required this.consequence,
    required this.remedy,
  });

  factory VehicleRecall.fromJson(Map<String, dynamic> json) {
    return VehicleRecall(
      component: json['component'] ?? '',
      summary: json['summary'] ?? '',
      consequence: json['consequence'] ?? '',
      remedy: json['remedy'] ?? '',
    );
  }
}

/// VIN Lookup Result from auto-detection
class VinLookupResult {
  final String vinStatus;
  final String? vinNumber;
  final VinVehicleDetails? vehicleDetails;
  final VinCrossCheck? crossCheck;

  VinLookupResult({
    required this.vinStatus,
    this.vinNumber,
    this.vehicleDetails,
    this.crossCheck,
  });

  factory VinLookupResult.fromJson(Map<String, dynamic> json) {
    return VinLookupResult(
      vinStatus: json['vin_status'] ?? 'Unknown',
      vinNumber: json['vin_number'],
      vehicleDetails: json['vehicle_details'] != null
          ? VinVehicleDetails.fromJson(json['vehicle_details'])
          : null,
      crossCheck: json['cross_check'] != null
          ? VinCrossCheck.fromJson(json['cross_check'])
          : null,
    );
  }
}

/// Vehicle details from VIN decode
class VinVehicleDetails {
  final String? make;
  final String? model;
  final int? year;
  final String? trim;
  final String? bodyType;
  final String? engine;
  final String? transmission;
  final String? drivetrain;
  final String? fuelType;
  final String? vehicleType;
  final String? plantCountry;
  final List<Map<String, dynamic>> recalls;
  final int recallCount;

  VinVehicleDetails({
    this.make,
    this.model,
    this.year,
    this.trim,
    this.bodyType,
    this.engine,
    this.transmission,
    this.drivetrain,
    this.fuelType,
    this.vehicleType,
    this.plantCountry,
    this.recalls = const [],
    this.recallCount = 0,
  });

  factory VinVehicleDetails.fromJson(Map<String, dynamic> json) {
    return VinVehicleDetails(
      make: json['make'],
      model: json['model'],
      year: json['year'],
      trim: json['trim'],
      bodyType: json['body_type'],
      engine: json['engine'],
      transmission: json['transmission'],
      drivetrain: json['drivetrain'],
      fuelType: json['fuel_type'],
      vehicleType: json['vehicle_type'],
      plantCountry: json['plant_country'],
      recalls:
          (json['recalls'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      recallCount: json['recall_count'] ?? 0,
    );
  }
}

/// Cross-check result between VIN and contract
class VinCrossCheck {
  final bool mismatchDetected;
  final List<String> mismatchDetails;
  final int confidenceScore;

  VinCrossCheck({
    required this.mismatchDetected,
    this.mismatchDetails = const [],
    this.confidenceScore = 100,
  });

  factory VinCrossCheck.fromJson(Map<String, dynamic> json) {
    return VinCrossCheck(
      mismatchDetected: json['mismatch_detected'] ?? false,
      mismatchDetails:
          (json['mismatch_details'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      confidenceScore: json['confidence_score'] ?? 100,
    );
  }
}

/// Sprint 9: Detailed 12-Section Analysis
class DetailedAnalysis {
  final SectionVehicleDetails vehicleDetails;
  final SectionLeasePayments leasePaymentTerms;
  final SectionLeaseDuration leaseDuration;
  final SectionMileage mileageUsageLimits;
  final SectionMaintenance maintenanceResponsibilities;
  final SectionInsurance insuranceRequirements;
  final SectionDamage damageAndWearConditions;
  final SectionEarlyTermination earlyTerminationTerms;
  final SectionOwnership ownershipTerms;
  final SectionUsageRestrictions usageRestrictions;
  final SectionLegal defaultAndLegalClauses;
  final SectionEndOfLease endOfLeaseProcess;
  final List<String> missingSections;
  final String summary;
  final int confidenceScore;

  DetailedAnalysis({
    required this.vehicleDetails,
    required this.leasePaymentTerms,
    required this.leaseDuration,
    required this.mileageUsageLimits,
    required this.maintenanceResponsibilities,
    required this.insuranceRequirements,
    required this.damageAndWearConditions,
    required this.earlyTerminationTerms,
    required this.ownershipTerms,
    required this.usageRestrictions,
    required this.defaultAndLegalClauses,
    required this.endOfLeaseProcess,
    this.missingSections = const [],
    this.summary = '',
    this.confidenceScore = 0,
  });

  factory DetailedAnalysis.fromJson(Map<String, dynamic> json) {
    return DetailedAnalysis(
      vehicleDetails: SectionVehicleDetails.fromJson(
        json['vehicle_details'] ?? {},
      ),
      leasePaymentTerms: SectionLeasePayments.fromJson(
        json['lease_payment_terms'] ?? {},
      ),
      leaseDuration: SectionLeaseDuration.fromJson(
        json['lease_duration'] ?? {},
      ),
      mileageUsageLimits: SectionMileage.fromJson(
        json['mileage_usage_limits'] ?? {},
      ),
      maintenanceResponsibilities: SectionMaintenance.fromJson(
        json['maintenance_responsibilities'] ?? {},
      ),
      insuranceRequirements: SectionInsurance.fromJson(
        json['insurance_requirements'] ?? {},
      ),
      damageAndWearConditions: SectionDamage.fromJson(
        json['damage_and_wear_conditions'] ?? {},
      ),
      earlyTerminationTerms: SectionEarlyTermination.fromJson(
        json['early_termination_terms'] ?? {},
      ),
      ownershipTerms: SectionOwnership.fromJson(json['ownership_terms'] ?? {}),
      usageRestrictions: SectionUsageRestrictions.fromJson(
        json['usage_restrictions'] ?? {},
      ),
      defaultAndLegalClauses: SectionLegal.fromJson(
        json['default_and_legal_clauses'] ?? {},
      ),
      endOfLeaseProcess: SectionEndOfLease.fromJson(
        json['end_of_lease_process'] ?? {},
      ),
      missingSections:
          (json['missing_sections'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      summary: json['summary'] ?? '',
      confidenceScore: json['confidence_score'] ?? 0,
    );
  }
}

class ReviewRisk {
  final String clause;
  final String reason;

  ReviewRisk({required this.clause, required this.reason});

  factory ReviewRisk.fromJson(Map<String, dynamic> json) {
    return ReviewRisk(
      clause: json['clause'] ?? '',
      reason: json['reason'] ?? '',
    );
  }
}

class SectionVehicleDetails {
  final String make;
  final String model;
  final String variantTrim;
  final String manufacturingYear;
  final String vin;
  final String registrationNumber;
  final String vehicleCondition;
  final List<ReviewRisk> riskFlags;

  SectionVehicleDetails({
    required this.make,
    required this.model,
    required this.variantTrim,
    required this.manufacturingYear,
    required this.vin,
    required this.registrationNumber,
    required this.vehicleCondition,
    this.riskFlags = const [],
  });

  factory SectionVehicleDetails.fromJson(Map<String, dynamic> json) {
    return SectionVehicleDetails(
      make: json['make'] ?? "Not Mentioned",
      model: json['model'] ?? "Not Mentioned",
      variantTrim: json['variant_trim'] ?? "Not Mentioned",
      manufacturingYear: json['manufacturing_year'] ?? "Not Mentioned",
      vin: json['vin'] ?? "Not Mentioned",
      registrationNumber: json['registration_number'] ?? "Not Mentioned",
      vehicleCondition: json['vehicle_condition'] ?? "Not Mentioned",
      riskFlags:
          (json['risk_flags'] as List?)
              ?.map((e) => ReviewRisk.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SectionLeasePayments {
  final String monthlyPaymentAmount;
  final String securityDeposit;
  final String paymentDueDate;
  final String latePaymentPenalties;
  final String taxesAndCharges;
  final List<ReviewRisk> riskFlags;

  SectionLeasePayments({
    required this.monthlyPaymentAmount,
    required this.securityDeposit,
    required this.paymentDueDate,
    required this.latePaymentPenalties,
    required this.taxesAndCharges,
    this.riskFlags = const [],
  });

  factory SectionLeasePayments.fromJson(Map<String, dynamic> json) {
    return SectionLeasePayments(
      monthlyPaymentAmount: json['monthly_payment_amount'] ?? "Not Mentioned",
      securityDeposit: json['security_deposit'] ?? "Not Mentioned",
      paymentDueDate: json['payment_due_date'] ?? "Not Mentioned",
      latePaymentPenalties: json['late_payment_penalties'] ?? "Not Mentioned",
      taxesAndCharges: json['taxes_and_charges'] ?? "Not Mentioned",
      riskFlags:
          (json['risk_flags'] as List?)
              ?.map((e) => ReviewRisk.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SectionLeaseDuration {
  final String leaseStartDate;
  final String leaseEndDate;
  final String totalLeasePeriod;
  final List<ReviewRisk> riskFlags;

  SectionLeaseDuration({
    required this.leaseStartDate,
    required this.leaseEndDate,
    required this.totalLeasePeriod,
    this.riskFlags = const [],
  });

  factory SectionLeaseDuration.fromJson(Map<String, dynamic> json) {
    return SectionLeaseDuration(
      leaseStartDate: json['lease_start_date'] ?? "Not Mentioned",
      leaseEndDate: json['lease_end_date'] ?? "Not Mentioned",
      totalLeasePeriod: json['total_lease_period'] ?? "Not Mentioned",
      riskFlags:
          (json['risk_flags'] as List?)
              ?.map((e) => ReviewRisk.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SectionMileage {
  final String allowedMileageLimit;
  final String excessMileageCharges;
  final List<ReviewRisk> riskFlags;

  SectionMileage({
    required this.allowedMileageLimit,
    required this.excessMileageCharges,
    this.riskFlags = const [],
  });

  factory SectionMileage.fromJson(Map<String, dynamic> json) {
    return SectionMileage(
      allowedMileageLimit: json['allowed_mileage_limit'] ?? "Not Mentioned",
      excessMileageCharges: json['excess_mileage_charges'] ?? "Not Mentioned",
      riskFlags:
          (json['risk_flags'] as List?)
              ?.map((e) => ReviewRisk.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SectionMaintenance {
  final String regularMaintenanceResponsibility;
  final String repairCostResponsibility;
  final String modificationRestrictions;
  final String vehicleConditionRequirements;
  final List<ReviewRisk> riskFlags;

  SectionMaintenance({
    required this.regularMaintenanceResponsibility,
    required this.repairCostResponsibility,
    required this.modificationRestrictions,
    required this.vehicleConditionRequirements,
    this.riskFlags = const [],
  });

  factory SectionMaintenance.fromJson(Map<String, dynamic> json) {
    return SectionMaintenance(
      regularMaintenanceResponsibility:
          json['regular_maintenance_responsibility'] ?? "Not Mentioned",
      repairCostResponsibility:
          json['repair_cost_responsibility'] ?? "Not Mentioned",
      modificationRestrictions:
          json['modification_restrictions'] ?? "Not Mentioned",
      vehicleConditionRequirements:
          json['vehicle_condition_requirements'] ?? "Not Mentioned",
      riskFlags:
          (json['risk_flags'] as List?)
              ?.map((e) => ReviewRisk.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SectionInsurance {
  final String requiredInsuranceType;
  final String insurancePaymentResponsibility;
  final String accidentLiabilityTerms;
  final List<ReviewRisk> riskFlags;

  SectionInsurance({
    required this.requiredInsuranceType,
    required this.insurancePaymentResponsibility,
    required this.accidentLiabilityTerms,
    this.riskFlags = const [],
  });

  factory SectionInsurance.fromJson(Map<String, dynamic> json) {
    return SectionInsurance(
      requiredInsuranceType: json['required_insurance_type'] ?? "Not Mentioned",
      insurancePaymentResponsibility:
          json['insurance_payment_responsibility'] ?? "Not Mentioned",
      accidentLiabilityTerms:
          json['accident_liability_terms'] ?? "Not Mentioned",
      riskFlags:
          (json['risk_flags'] as List?)
              ?.map((e) => ReviewRisk.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SectionDamage {
  final String normalWearAndTearDefinition;
  final String excessDamageCharges;
  final String returnInspectionProcess;
  final List<ReviewRisk> riskFlags;

  SectionDamage({
    required this.normalWearAndTearDefinition,
    required this.excessDamageCharges,
    required this.returnInspectionProcess,
    this.riskFlags = const [],
  });

  factory SectionDamage.fromJson(Map<String, dynamic> json) {
    return SectionDamage(
      normalWearAndTearDefinition:
          json['normal_wear_and_tear_definition'] ?? "Not Mentioned",
      excessDamageCharges: json['excess_damage_charges'] ?? "Not Mentioned",
      returnInspectionProcess:
          json['return_inspection_process'] ?? "Not Mentioned",
      riskFlags:
          (json['risk_flags'] as List?)
              ?.map((e) => ReviewRisk.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SectionEarlyTermination {
  final String earlyTerminationAllowed;
  final String terminationCharges;
  final String cancellationConditions;
  final String contractBreachConsequences;
  final List<ReviewRisk> riskFlags;

  SectionEarlyTermination({
    required this.earlyTerminationAllowed,
    required this.terminationCharges,
    required this.cancellationConditions,
    required this.contractBreachConsequences,
    this.riskFlags = const [],
  });

  factory SectionEarlyTermination.fromJson(Map<String, dynamic> json) {
    return SectionEarlyTermination(
      earlyTerminationAllowed:
          json['early_termination_allowed'] ?? "Not Mentioned",
      terminationCharges: json['termination_charges'] ?? "Not Mentioned",
      cancellationConditions:
          json['cancellation_conditions'] ?? "Not Mentioned",
      contractBreachConsequences:
          json['contract_breach_consequences'] ?? "Not Mentioned",
      riskFlags:
          (json['risk_flags'] as List?)
              ?.map((e) => ReviewRisk.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SectionOwnership {
  final String vehicleOwnershipHolder;
  final String endOfLeasePurchaseOption;
  final String purchasePriceOrFormula;
  final String vehicleReturnConditions;
  final List<ReviewRisk> riskFlags;

  SectionOwnership({
    required this.vehicleOwnershipHolder,
    required this.endOfLeasePurchaseOption,
    required this.purchasePriceOrFormula,
    required this.vehicleReturnConditions,
    this.riskFlags = const [],
  });

  factory SectionOwnership.fromJson(Map<String, dynamic> json) {
    return SectionOwnership(
      vehicleOwnershipHolder:
          json['vehicle_ownership_holder'] ?? "Not Mentioned",
      endOfLeasePurchaseOption:
          json['end_of_lease_purchase_option'] ?? "Not Mentioned",
      purchasePriceOrFormula:
          json['purchase_price_or_formula'] ?? "Not Mentioned",
      vehicleReturnConditions:
          json['vehicle_return_conditions'] ?? "Not Mentioned",
      riskFlags:
          (json['risk_flags'] as List?)
              ?.map((e) => ReviewRisk.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SectionUsageRestrictions {
  final String authorizedDrivers;
  final String commercialUseRestrictions;
  final String geographicUsageRestrictions;
  final List<ReviewRisk> riskFlags;

  SectionUsageRestrictions({
    required this.authorizedDrivers,
    required this.commercialUseRestrictions,
    required this.geographicUsageRestrictions,
    this.riskFlags = const [],
  });

  factory SectionUsageRestrictions.fromJson(Map<String, dynamic> json) {
    return SectionUsageRestrictions(
      authorizedDrivers: json['authorized_drivers'] ?? "Not Mentioned",
      commercialUseRestrictions:
          json['commercial_use_restrictions'] ?? "Not Mentioned",
      geographicUsageRestrictions:
          json['geographic_usage_restrictions'] ?? "Not Mentioned",
      riskFlags:
          (json['risk_flags'] as List?)
              ?.map((e) => ReviewRisk.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SectionLegal {
  final String defaultConditions;
  final String repossessionRights;
  final String disputeResolutionMethod;
  final List<ReviewRisk> riskFlags;

  SectionLegal({
    required this.defaultConditions,
    required this.repossessionRights,
    required this.disputeResolutionMethod,
    this.riskFlags = const [],
  });

  factory SectionLegal.fromJson(Map<String, dynamic> json) {
    return SectionLegal(
      defaultConditions: json['default_conditions'] ?? "Not Mentioned",
      repossessionRights: json['repossession_rights'] ?? "Not Mentioned",
      disputeResolutionMethod:
          json['dispute_resolution_method'] ?? "Not Mentioned",
      riskFlags:
          (json['risk_flags'] as List?)
              ?.map((e) => ReviewRisk.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SectionEndOfLease {
  final String returnProcedure;
  final String renewalOptions;
  final String finalSettlementTerms;
  final List<ReviewRisk> riskFlags;

  SectionEndOfLease({
    required this.returnProcedure,
    required this.renewalOptions,
    required this.finalSettlementTerms,
    this.riskFlags = const [],
  });

  factory SectionEndOfLease.fromJson(Map<String, dynamic> json) {
    return SectionEndOfLease(
      returnProcedure: json['return_procedure'] ?? "Not Mentioned",
      renewalOptions: json['renewal_options'] ?? "Not Mentioned",
      finalSettlementTerms: json['final_settlement_terms'] ?? "Not Mentioned",
      riskFlags:
          (json['risk_flags'] as List?)
              ?.map((e) => ReviewRisk.fromJson(e))
              .toList() ??
          [],
    );
  }
}

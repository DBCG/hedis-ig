/*
Colorectal Cancer Screening (COL)
*/

library COL_FHIR version '1.0.1'

//using FHIR version '3.0.1'
using FHIR version '3.0.0'

/*
Description
The percentage of members 50-75 years of age who had appropriate screening for colorectal cancer.
*/

/*
It is an outstanding question whether implementers would have an easier time dealing
with single code system value sets for retrieval of data, or if the grouping value sets
are easier to deal with. This mesaure is modified to take the approach of unioning
the results in CQL, where the BCS and CCS measures take the grouping value set
approach.
*/

valueset "Colonoscopy Value Set (CPT)": '2.16.840.1.113883.3.464.1004.1064.29' // CPT
valueset "Colonoscopy Value Set (HCPCS)": '2.16.840.1.113883.3.464.1004.1064.30' // HCPCS
valueset "Colonoscopy Value Set (ICD9)": '2.16.840.1.113883.3.464.1004.1064.31' // ICD9CMProc

valueset "Colorectal Cancer Value Set (ICD10)": '2.16.840.1.113883.3.464.1004.1065.32' // ICD10CM
valueset "Colorectal Cancer Value Set (ICD9)": '2.16.840.1.113883.3.464.1004.1065.33' // ICD9CM

valueset "CT Colonography Value Set": '2.16.840.1.113883.3.464.1004.1421.34' // CPT

valueset "FIT-DNA Value Set (CPT)": '2.16.840.1.113883.3.464.1004.1420.35' // CPT
valueset "FIT-DNA Value Set (HCPCS)": '2.16.840.1.113883.3.464.1004.1420.36' // HCPCS
valueset "FIT-DNA Value Set (LOINC)": '2.16.840.1.113883.3.464.1004.1420.37' // LOINC

valueset "Flexible Sigmoidoscopy Value Set (CPT)": '2.16.840.1.113883.3.464.1004.1102.38' // CPT
valueset "Flexible Sigmoidoscopy Value Set (HCPCS)": '2.16.840.1.113883.3.464.1004.1102.39' // HCPCS
valueset "Flexible Sigmoidoscopy Value Set (ICD9)": '2.16.840.1.113883.3.464.1004.1102.40' // ICD9CMProc

valueset "FOBT Value Set (CPT)": '2.16.840.1.113883.3.464.1004.1093.41' // CPT
valueset "FOBT Value Set (HCPCS)": '2.16.840.1.113883.3.464.1004.1093.42' // HCPCS
valueset "FOBT Value Set (ICD9)": '2.16.840.1.113883.3.464.1004.1093.43' // ICD9CMProc

valueset "Total Colectomy Value Set (CPT)": '2.16.840.1.113883.3.464.1004.1250.44' // CPT
valueset "Total Colectomy Value Set (ICD10)": '2.16.840.1.113883.3.464.1004.1250.45' // ICD10PCS
valueset "Total Colectomy Value Set (ICD9)": '2.16.840.1.113883.3.464.1004.1250.46' // ICD9CMProc

// valueset "Hospice Value Set": 'TODO'
// valueset "Encounter Inpatient": '2.16.840.1.113883.3.666.5.307' version 'urn:hl7:version:eCQM%20Update%202017-05-05'
// valueset "Discharged to Home for Hospice Care": '2.16.840.1.113883.3.117.1.7.1.209' version 'urn:hl7:version:eCQM%20Update%202017-05-05'
// valueset "Discharged to Health Care Facility for Hospice Care": '2.16.840.1.113883.3.117.1.7.1.207' version 'urn:hl7:version:eCQM%20Update%202017-05-05'
// valueset "Hospice care ambulatory": '2.16.840.1.113762.1.4.1108.15' version 'urn:hl7:version:eCQM%20Update%202017-05-05'
// valueset "X Commercial Coverage Value Set": 'TODO'
// valueset "X Medicaid Coverage Value Set": 'TODO'
// valueset "X Medicare Coverage Value Set": 'TODO'
// valueset "X Institutional SNP Value Set": 'TODO'
// valueset "X Long-Term in Institution Value Set": 'TODO'

/*
This library has an explicit parameter which is the product line.
Recognized normal arguments are {'commercial', 'medicaid', 'medicare'}.
If one of these normal arguments is given, the patient will only be
considered to be in the Initial Population if they have an appropriate
continuous enrollment in that kind of medical plan.
If instead a null argument is given, their enrollment status will have no
effect on whether they are considered to be in the Initial Population.
If instead some other argument is given (an unrecognized plan type),
the patient will unconditionally NOT be in the Initial Population.
*/

parameter "Product Line" String

/*
This library has an explicit parameter which is the measurement year.
While the actual parameter's type accepts all intervals, this library
expects it will only be given arguments corresponding exactly to one whole
calendar year, and it will not behave properly otherwise; 2017 for example:
Interval[DateTime(2017,1,1,0,0,0,0), DateTime(2018,1,1,0,0,0,0))
*/

parameter "Measurement Period" Interval<DateTime>

define "First Predecessor Year":
	Interval[start of "Measurement Period" - 1 year, end of "Measurement Period" - 1 year)

define "Second Predecessor Year":
	Interval[start of "Measurement Period" - 2 years, end of "Measurement Period" - 2 years)

define "Third Predecessor Quarter":
	Interval[start of "Measurement Period" - 2 years - 3 months, end of "Measurement Period" - 3 years)

define "Lookback Interval Two More Years":
	Interval[start of "Measurement Period" - 2 years, end of "Measurement Period")

define "Lookback Interval Four More Years":
	Interval[start of "Measurement Period" - 4 years, end of "Measurement Period")

define "Lookback Interval Nine More Years":
	Interval[start of "Measurement Period" - 9 years, end of "Measurement Period")

/*
This library evaluates with respect to exactly 1 candidate patient at a time,
that patient being given by the special context parameter Patient.
*/

context Patient

/*
Initial Population
Product lines -- Commercial, Medicaid, Medicare (report each product line separately).
*/

define "Initial Population":
	"Is Age 51 to 75 at End"
/*
		and (not "Is In Hospice")
		and "Is In Applicable Product Line"
*/

define "Is Age 51 to 75 at End":
	CalendarAgeInYearsAt(Patient.birthDate.value, end of "Measurement Period") between 51 and 75

/*
define "Is In Hospice":
	exists(
		[Encounter: "Hospice Value Set"] Enc
			where Enc.status.value in { 'planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished' }
				and PeriodToIntervalOfDT(Enc.period) overlaps day of "Measurement Period"
	)
	or
	exists(
		[Encounter: "Encounter Inpatient"] DischargeHospice
			where DischargeHospice.status.value in { 'planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished' }
				and (CodingToCode(DischargeHospice.hospitalization.dischargeDisposition.coding)
						in "Discharged to Home for Hospice Care"
					or CodingToCode(DischargeHospice.hospitalization.dischargeDisposition.coding)
						in "Discharged to Health Care Facility for Hospice Care")
				and PeriodToIntervalOfDT(DischargeHospice.period) ends during day of "Measurement Period"
	)
	or
	exists(
		[ProcedureRequest: "Hospice care ambulatory"] HospiceOrder
			where HospiceOrder.status.value in { 'active', 'completed' }
				and HospiceOrder.authoredOn.value during day of "Measurement Period"
	)
	or
	exists(
		[Procedure: "Hospice care ambulatory"] HospicePerformed
			where HospicePerformed.status.value in { 'preparation', 'in-progress', 'suspended', 'aborted', 'completed' }
				and HospicePerformed.performed overlaps day of "Measurement Period"
	)

define "Is In Applicable Product Line":
	case
		when ("Product Line" ~ null) then true
		when ("Product Line" = 'commercial') then "Is Continuous Enrollment"
		when ("Product Line" = 'medicaid') then "Is Continuous Enrollment"
		when ("Product Line" = 'medicare') then
			("Is Continuous Enrollment"
				and (if "Is Age 65 Plus at Start"
					then ("Is Enrolled in Institutional SNP"
						or "Is Living Long-Term in Institution")
					else false))
		else false
	end

define "Enrollment Periods":
	collapse(
		[Coverage] Cov
			where Cov.status.value in { 'active', 'cancelled' }
				and case "Product Line"
					when 'commercial' then
						CodingToCode(Cov.type.coding) in "X Commercial Coverage Value Set"
					when 'medicaid' then
						CodingToCode(Cov.type.coding) in "X Medicaid Coverage Value Set"
					when 'medicare' then
						CodingToCode(Cov.type.coding) in "X Medicare Coverage Value Set"
					else false
				end
			return PeriodToIntervalOfDT(Cov.period)
	)
	// We assume [Coverage] in Patient context implicitly has this filter:
	// Cov.beneficiary.identifier ~ Patient.identifier
	// ... and that the paitient is not connected as a policy holder or payor.
	// TODO: Properly determine organization(s) for the product line.
	// Note: collapse() also puts the resulting intervals in order.

define function "Enrollment Periods In Year"(Year Interval<DateTime>):
	"Enrollment Periods" EnrP
		where EnrP overlaps day of Year
		return EnrP intersect day of Year

define function "Is Continuous Enrollment In Year"(Year Interval<DateTime>):
	case Count("Enrollment Periods In Year"(Year))
		when 1 then (
			(("Enrollment Periods In Year"(Year)[0] starts Year)
				and ((difference in days between
						end of "Enrollment Periods In Year"(Year)[0]
						and end of Year
					) <= 45))
			or
			(("Enrollment Periods In Year"(Year)[0] ends Year)
				and ((difference in days between
						start of "Enrollment Periods In Year"(Year)[0]
						and start of Year
					) <= 45))
		)
		when 2 then (
			("Enrollment Periods In Year"(Year)[0] starts Year)
				and ("Enrollment Periods In Year"(Year)[1] ends Year)
				and ((difference in days between
						end of "Enrollment Periods In Year"(Year)[0]
						and start of "Enrollment Periods In Year"(Year)[1]
					) <= 45)
		)
		else false
	end

define function "Is Continuous Enrollment In Quarter"(Quarter Interval<DateTime>):
	case Count("Enrollment Periods In Year"(Quarter))
		when 1 then ("Enrollment Periods In Year"(Quarter)[0] = Quarter)
		else false
	end

define "Is Continuous Enrollment":
	"Is Continuous Enrollment In Year"("Measurement Period")
		and "Is Continuous Enrollment In Year"("First Predecessor Year")
		and "Is Continuous Enrollment In Year"("Second Predecessor Year")
		// and "Is Continuous Enrollment In Quarter"("Third Predecessor Quarter")

define "Is Age 65 Plus at Start":
	CalendarAgeInYearsAt(Patient.birthDate.value, start of "Measurement Period") >= 65

define "Is Enrolled in Institutional SNP":
	exists(
		[Encounter: "X Institutional SNP Value Set"] Enc
			where Enc.status.value in { 'planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished' }
				and PeriodToIntervalOfDT(Enc.period) overlaps day of "Measurement Period"
	)
	// TODO: Determine properly whether the patient was in SNP during the measurement year.

define "Is Living Long-Term in Institution":
	exists(
		[Encounter: "X Long-Term in Institution Value Set"] Enc
			where Enc.status.value in { 'planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished' }
				and PeriodToIntervalOfDT(Enc.period) overlaps day of "Measurement Period"
	)
	// TODO: Determine properly whether the patient was in LTI during the measurement year.
*/

/*
Administrative Specification
*/

define "Denominator":
	// was "Initial Population", but that will always be true if this expression is executed
    true

define "Numerator":
	"Is Colorectal Cancer Screening"

define "Is Colorectal Cancer Screening":
	"Is Fecal Occult Blood Test In Last Year"
		or "Is Flexible Sigmoidoscopy In Last Five Years"
		or "Is Colonoscopy In Last Ten Years"
		or "Is CT Colonography In Last Five Years"
		or "Is FIT-DNA Test In Last Three Years"

define "FOBT Observations":
	[Observation: "FOBT Value Set (CPT)"]
		union [Observation: "FOBT Value Set (HCPCS)"]
		union [Observation: "FOBT Value Set (ICD9)"]

define "Is Fecal Occult Blood Test In Last Year":
	exists(
		"FOBT Observations" Obs
			where Obs.status.value in { 'final', 'amended' }
				and Obs.effective.value in day of "Measurement Period"
	)

define "Flexible Sigmoidoscopy Reports":
	[DiagnosticReport: "Flexible Sigmoidoscopy Value Set (CPT)"]
		union [DiagnosticReport: "Flexible Sigmoidoscopy Value Set (HCPCS)"]
		union [DiagnosticReport: "Flexible Sigmoidoscopy Value Set (ICD9)"]

define "Is Flexible Sigmoidoscopy In Last Five Years":
	exists(
		"Flexible Sigmoidoscopy Reports" DiagRep
			where DiagRep.status.value in { 'preliminary', 'final', 'amended', 'corrected', 'appended' }
				and PeriodToIntervalOfDT(DiagRep.effective) overlaps day of "Lookback Interval Four More Years"
	)

define "Colonoscopy Reports":
	[DiagnosticReport: "Colonoscopy Value Set (CPT)"]
		union [DiagnosticReport: "Colonoscopy Value Set (HCPCS)"]
		union [DiagnosticReport: "Colonoscopy Value Set (ICD9)"]

define "Is Colonoscopy In Last Ten Years":
	exists(
		"Colonoscopy Reports" DiagRep
			where DiagRep.status.value in { 'preliminary', 'final', 'amended', 'corrected', 'appended' }
				and PeriodToIntervalOfDT(DiagRep.effective) overlaps day of "Lookback Interval Nine More Years"
	)

define "Is CT Colonography In Last Five Years":
	exists(
		[DiagnosticReport: "CT Colonography Value Set"] DiagRep
			where DiagRep.status.value in { 'preliminary', 'final', 'amended', 'corrected', 'appended' }
				and PeriodToIntervalOfDT(DiagRep.effective) overlaps day of "Lookback Interval Four More Years"
	)

define "FIT-DNA Observations":
	[Observation: "FIT-DNA Value Set (CPT)"]
		union [Observation: "FIT-DNA Value Set (HCPCS)"]
		union [Observation: "FIT-DNA Value Set (LOINC)"]

define "Is FIT-DNA Test In Last Three Years":
	exists(
		"FIT-DNA Observations" Obs
			where Obs.status.value in { 'final', 'amended' }
				and Obs.effective.value in day of "Lookback Interval Two More Years"
	)

define "Denominator Exclusion":
	"Is Colorectal Cancer"
			or "Is Total Colectomy"

define "Colorectal Cancer Conditions":
	[Condition: "Colorectal Cancer Value Set (ICD10)"]
		union [Condition: "Colorectal Cancer Value Set (ICD9)"]

define "Is Colorectal Cancer":
	exists(
		"Colorectal Cancer Conditions" Cond
			where Cond.verificationStatus.value = 'confirmed'
				and Cond.assertedDate.value before day of end of "Measurement Period"
	)

define "Total Colectomy Procedures":
	[Procedure: "Total Colectomy Value Set (CPT)"]
		union [Procedure: "Total Colectomy Value Set (ICD10)"]
		union [Procedure: "Total Colectomy Value Set (ICD9)"]

define "Is Total Colectomy":
	exists(
		"Total Colectomy Procedures" Proc
			where Proc.status.value = 'completed'
				and end of PeriodToIntervalOfDT(Proc.performed) before day of end of "Measurement Period"
	)

/*
Hybrid Specification
TODO, if needed
*/


/*
Utility Functions
*/

define function PeriodToIntervalOfDT(value FHIR.Period):
	Interval[value."start".value, value."end".value]

define function CodingToCode(coding FHIR.Coding):
	System.Code {
		code: coding.code.value,
		system: coding.system.value,
		version: coding.version.value,
		display: coding.display.value
	}
	// From FHIRHelpers

define function "ToDate"(Value DateTime ):
	DateTime(year from Value, month from Value, day from Value, 0, 0, 0, 0, timezone from Value)

define function CalendarAgeInYearsAt(BirthDateTime DateTime, AsOf DateTime):
    years between ToDate(BirthDateTime)and ToDate(AsOf)
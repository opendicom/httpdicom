# httpdicom

Custodian bridging http internet with DICOM local network devices.
Provides to the world rest service which it forwards to devices in local DICOM networks by means of dicomweb, dicom and/or sql and filesystem protocols.
Accesorily, it can forward the http call to another httpdicom in the world for remote execution.
 
## subset DICOMWEB
 - qido studies, series, instances (content-type application/dicom+json)
   - no proxying of studies/{StudyIUID}/series
   - no proxying of studies/{StudyIUID}/series/{SeriesIUID}/instances
 - wado-rs content-type multipart/related; type="application/dicom"
 - metadata
 - wado-uri

## additions
 - encapsulated (returns the contents of attribute 00420010 with corresponding content-type)
 - zipped/wadors (returns the dicom instances zipped, instead of a multipart/related)
 - datatables/studies, patient, series (returns data source consummed by datatables without modification)
 - wado-rs content-type multipart/related; type="application/dicom" /export
 - wado-uri /export

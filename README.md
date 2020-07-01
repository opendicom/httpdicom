# httpdicom

Proxy REST for propietary and DICOMWEB services reaching:
 - local DICOMWEB PACS using HTTP,
 - local DICOM PACS using SQL, WADO-URI (and in the future direct filesystem read access),
 - or remote instance of httpdicom using HTTPS

## additions
 - studyToken (for secure datatables, weasis, cornerstone and dicomzip services)
 - XML (CDA) report (returns the contents of attribute 00420010)
 - mwlitem (interface for Modality worklist)
 - store (normalize dicom instances before adding them to a PACS
 
(written in objective-C using GCDWebServer by Pierre-Olivier Latour core http server logics) 

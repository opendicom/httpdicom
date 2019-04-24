# Servicio Rest /mwlitem

Recibe ordenes de servicio en formato "xhtml5 form" o  "json map"  por http, lo procesa y crea :

- el (los) items de lista de trabajo (mwl) DICOM correspondiente(s),
- un documento DICOM CDA con la orden de servicio
- un usuario en el sistema de acceso web.

El formato jspon se presenta así:

```
 {
 "pacs"                       :"",
 
 "apellido1"                  :"",
 "apellido2"                  :"",
 "nombres"                    :"",
 
 "PatientBirthDate"           :"",
 "PatientSex"                 :"",

 "PatientID"                  :"",
 "PatientIDCountry"           :"",
 "PatientIDType"              :"",

 "password"                      :"",

 "AccessionNumber"            :"",
 "issuer"                     :"",
 "issuerType"                 :"",
 
 "StudyDescription"           :"",
 
 "Priority"                   :"",
 "ReferringPhysiciansName"    :"",
 "NameofPhysicianReadingStudy":"",
 
 "msg"                        :"",
 "enclosurePdf"               :"",
 
 "sps1Service"                :"",
 "sps1Modality"              :"",
 "sps1StationAETitle"         :"",
 "sps1Technician"             :"",
 "sps1ProtocolCode"           :"",
 
 "sps2Service"                   :"",
 "sps2Modality"              :"",
 "sps2StationAETitle"         :"",
 "sps2Technician"             :"",
 "sps2ProtocolCode"           :"",
 
 "sps3Service"                   :"",
 "sps3Modality"              :"",
 "sps3StationAETitle"         :"",
 "sps3Technician"             :"",
 "sps3ProtocolCode"           :"",
 
 "sps4Service"                   :"",
 "sps4Modality"              :"",
 "sps4StationAETitle"         :"",
 "sps4Technician"             :"",
 "sps4ProtocolCode"           :"",
 }
```
Varios elementos del json son opcionales.

El json mínimo contiene:

```
 {
 "apellido1"                  :"",

 "PatientID"                  :"",
 "PatientIDCountry"           :"",
 "PatientIDType"              :"",

 "AccessionNumber"            :"",
 "issuer"                     :"",
 "issuerType"                 :"",
 
 "sps1Modality"               :"",
 "sps1ProtocolCode"           :"",
 }
```


| elemento | sinonimo | opcional | default | formato | description | =ORMO01 | =DICOM |
|--|--|--|--|--|--|--|--|
| pacs |  | ? | definido in init | UID | identificador de la sucursal |  |  |
| familyName1 | apellido1 | 1 |  | mayusculas | apellido paternal del (de la) paciente | PID_5 | 00100010 |
| familyName2 | apellido2 | ? |  | mayusculas | apellido maternal del (de la) paciente | PID_6 | 00100010> 00101060 |
| givenNames | nombres | ? |  |  | mayusculas | PID_5 | 00100010^ |
| PatientBirthDate |  | ? |  | aaaammdd | fecha nacimiento del (de la) paciente | PID_7 | 00100030 |
| PatientSex |  | ? | O | O=other, M=masculino, F=feminino | sexo del (de la) paciente  | PID_8 | 00100040 |
| PatientID |  | 1 |  | SH | identificador del (de la) paciente | PID_3 | 00100020 |
| PatientIDCountry |  | 1 |  | ISO |  | PID_3 | 00100021 |
| PatientIDType |  | 1 |  | ICAE |  | PID_3 | 00100021 |
| password | clave | ? |  | >7 char |  |  |  |
| AccessionNumber |  | 1 |  | SH |  | OBR_18 | 00080050 |
| issuer | issuerLocal,issuerUniversal | 1 |  |  | issuer local no calificado por issuerType, issuer universal respecta el formato definido en issuerType |  |  |
| issuerType |  | ? | DNS, EUI64, ISO (OID), URI, UUID, X400, X500 |  |  |  |  |
| StudyDescription |  | ? | compilación de sps(x)ProtocolCode | código^significado^^codiguera (soporta también texto libre) | descripción del estudio | OBR_44 | 00321064(00321060) |
| Priority |  | ? |  |  |  | ORC_7_ | 00401003 |
| ReferrignPhysiciansName |  | ? |  |  |  | OBR_16 | 00321032 RequestingPhysician |
| NameOfPhysicianReadingStudy |  | ? |  |  |  |  |  |
| msg |  | ? |  |  |  |  |  |
| enclosurePdf |  | ? |  |  |  |  |  |
| sps1Service | sala | · |  |  |  |  |  |
| sps1Modality | modalidad | · |  |  |  | OBR_24 | 00080060* |
| sps1StationAETitle |  | · |  |  |  | OBR_21 | 00400001 |
| sps1Technician |  | ? |  |  |  | OBR_34 | 00400006 (PerformingPhysicianName) |
| sps1ProtocolCode |  | 1 |  | código^significado^codiguera (soporta también texto libre) |  | OBR_4 | 00400008(00040007) |
|  |  |  |  |  |  |  |  |
|  |  |  |  |  |  |  |  |
|  |  |  |  |  |  |  |  |
|  |  |  |  |  |  |  |  |
|  |  |  |  |  |  |  |  |
|  |  |  |  |  |  |  |  |

? = opcional

1 = obligatorio

· = por lo menos un elemento marcado por punto obligatorio

UID Unique IDentificator [12](.(0|1-9(0-9)*)*

SH= alfanumerico <16 char
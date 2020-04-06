# APPNOTE.TXT
# .ZIP File Format Specification
# 6.3.6 (April 26, 2019)
```
iso restricted by jacquesfauquex@gmail.com
```

2.2 Change Log
--------------

- 5.2 / 20030716          
    - Single Password Symmetric Encryption storage

- 6.1.0 / 20040120
    - Smartcard compatibility
    - Documentation on certificate storage

- 6.2.0 / 20040426
    - Introduction of Central Directory Encryption for encrypting metadata
    - Added OS X to Version Made By values

- 6.2.1 / 20050401
    - Added Extra Field placeholder for POSZIP using ID 0x4690
    - Clarified size field on "zip64 end of central directory record"

- 6.2.2 / 20060106
    - Documented Final Feature Specification for Strong Encryption
    - Clarifications and typographical corrections

- 6.3.0 / 20060929
    - Added tape positioning storage parameters
    - Expanded list of supported hash algorithms
    - Expanded list of supported compression algorithms
    - Expanded list of supported encryption algorithms
    - Added option for Unicode filename storage
    - Clarifications for consistent use of Data Descriptor records
    - Added additional "Extra Field" definitions

- 6.3.1 / 20070411
    - Corrected standard hash values for SHA-256/384/512

- 6.3.2 / 20070928
    - Added compression method 97
    - Documented InfoZIP "Extra Field" values for UTF-8 file name and file comment storage

- 6.3.3 / 20120901
    - Formatting changes to support easier referencing of this APPNOTE from other documents and standards  

- 6.3.4 / 20141001
    - Address change
 
- 6.3.5 / 20181131
    - Documented compression methods 16 and 99 (4.4.5, 4.6.1, 5.11, 5.17, APPENDIX E)
    - Corrected several typographical errors (2.1.2, 3.2, 4.1.1, 10.2)
    - Marked legacy algorithms as no longer suitable for use (4.4.5.1)
    - Added clarity on MS DOS time format (4.4.6)
    - Assign extrafield ID for Timestamps (4.5.2)
    - Field code description correction (A.2)
    - More consistent use of MAY/SHOULD/MUST
    - Expanded 0x0065 record attribute codes (B.2)
    - Initial information on 0x0022 Extra Data

- 6.3.6 / 20190426
    - Corrected typographical error (4.4.1.3) 

3.0 Notations
-------------

**3.1** Use of the term MUST or SHALL indicates a required element. 

**3.2** MUST NOT or SHALL NOT indicates an element is prohibited from use. 

**3.3** SHOULD indicates a RECOMMENDED element.

**3.4** SHOULD NOT indicates an element NOT RECOMMENDED for use.
   
**3.5** MAY indicates an OPTIONAL element.


4.1 What is a ZIP file
----------------------

**4.1.1** ZIP files MAY be identified by the standard .ZIP file extension although use of a file extension is not required.  Use of the extension .ZIPX is also recognized and MAY be used for ZIP files. Other common file extensions using the ZIP format include .JAR, .WAR, .DOCX, .XLSX, .PPTX, .ODT, .ODS, .ODP and others. Programs reading or writing ZIP files SHOULD rely on internal record signatures described in this document to identify files in this format.

**4.1.2** ZIP files SHOULD contain at least one file and MAY contain multiple files.  

**4.1.3** Data compression MAY be used to reduce the size of files placed into a ZIP file, but is not required.  This format supports the use of multiple data compression algorithms.  When compression is used, one of the documented compression algorithms MUST be used.  Implementors are advised to experiment with their data to determine which of the available algorithms provides the best compression for their needs. Compression method 8 (Deflate) is the method used by default by most ZIP compatible application programs.  


**4.1.4** Data encryption MAY be used to protect files within a ZIP file. Keying methods supported for encryption within this format include passwords and public/private keys.  Either MAY be used individually or in combination. Encryption MAY be applied to individual files. Additional security MAY be used through the encryption of ZIP file metadata stored within the Central Directory. See the section on the Strong Encryption Specification for information. Refer to the section in this document entitled "Incorporating PKWARE Proprietary Technology into Your Product" for more information.

**4.1.5** Data integrity MUST be provided for each file using CRC32.  
   
**4.1.6** Additional data integrity MAY be included through the use of digital signatures.  Individual files MAY be signed with one or more digital signatures. The Central Directory, if signed, MUST use a single signature.  

**4.1.7** Files MAY be placed within a ZIP file uncompressed or stored. The term "stored" as used in the context of this document means the file is copied into the ZIP file uncompressed.  

**4.1.8** Each data file placed into a ZIP file MAY be compressed, stored, encrypted or digitally signed independent of how other data files in the same ZIP file are archived.

**4.1.9** ZIP files MAY be streamed, split into segments (on fixed or on removable media) or "self-extracting".  Self-extracting ZIP files MUST include extraction code for a target platform within the ZIP file.  

**4.1.10** Extensibility is provided for platform or application specific needs through extra data fields that MAY be defined for custom purposes.  Extra data definitions MUST NOT conflict with existing documented record definitions.  

**4.1.11** Common uses for ZIP MAY also include the use of manifest files. Manifest files store application specific information within a file stored within the ZIP file.  This manifest file SHOULD be the first file in the ZIP file. This specification does not provide any information or guidance on the use of manifest files within ZIP files.  Refer to the application developer for information on using manifest files and for any additional profile information on using ZIP within an application.

**4.1.12** ZIP files MAY be placed within other ZIP files.

4.2 ZIP Metadata
----------------

**4.2.1** ZIP files are identified by metadata consisting of defined record types containing the storage information necessary for maintaining the files placed into a ZIP file.  Each record type MUST be identified using a header signature that identifies the record type.  Signature values begin with the two byte constant marker of 0x4b50, representing the characters "PK".


4.3 General Format of a .ZIP file
---------------------------------

**4.3.1** A ZIP file MUST contain an "end of central directory record". A ZIP file containing only an **"end of central directory record"** is considered an empty ZIP file.  Files MAY be added or replaced within a ZIP file, or deleted. A ZIP file MUST have only one **"end of central directory record"**.  Other records defined in this specification MAY be used as needed to support storage requirements for individual ZIP files.

**4.3.2** Each file placed into a ZIP file MUST be preceeded by  a **"local file header"** record for that file.  Each "local file header" MUST be accompanied by a corresponding **"central directory header"** record within the central directory section of the ZIP file.

**4.3.3** Files MAY be stored in arbitrary order within a ZIP file.  A ZIP file MAY span multiple volumes or it MAY be split into user-defined segment sizes. **All values MUST be stored in little-endian byte order unless otherwise specified in this document** for a specific data element. 

**4.3.4** Compression MUST NOT be applied to a "local file header", an "encryption header", or an "end of central directory record".  Individual "central directory records" MUST NOT be compressed, but the aggregate of all central directory records MAY be compressed.    

**4.3.5** File data MAY be followed by a "data descriptor" for the file.  Data descriptors are used to facilitate ZIP file streaming.  

 
**4.3.6** Overall .ZIP file format

      [local file header 1]
      [encryption header 1]
      [file data 1]
      [data descriptor 1]
      . 
      .
      .
      [local file header n]
      [encryption header n]
      [file data n]
      [data descriptor n]
      [archive extra data record] 
      [central directory header 1]
      .
      .
      .
      [central directory header n]
      [zip64 end of central directory record]
      [zip64 end of central directory locator] 
      [end of central directory record]


**4.3.7**  Local file header

      local file header signature     4 bytes  (0x04034b50)
      version needed to extract       2 bytes
      general purpose bit flag        2 bytes
      compression method              2 bytes
      last mod file time              2 bytes
      last mod file date              2 bytes
      crc-32                          4 bytes
      compressed size                 4 bytes
      uncompressed size               4 bytes
      file name length                2 bytes
      extra field length              2 bytes

      file name (variable size)
      extra field (variable size)

**4.3.8**  File data

- Immediately following the local header for a file SHOULD be placed the compressed or stored data for the file.
- If the file is encrypted, the encryption header for the file SHOULD be placed after the local header and before the file data. 
- The series of [local file header][encryption header][file data][data descriptor] repeats for each file in the .ZIP archive. 
- Zero-byte files, directories, and other file types that contain no content MUST NOT include file data.

**4.3.9**  Data descriptor

        crc-32                          4 bytes
        compressed size                 4 bytes
        uncompressed size               4 bytes

**4.3.9.1** This descriptor MUST exist if bit 3 of the general purpose bit flag is set (see below).  It is byte aligned and immediately follows the last byte of compressed data. This descriptor SHOULD be used only when it was not possible to seek in the output .ZIP file, e.g., when the output .ZIP file was standard output or a non-seekable device.  For ZIP64(tm) format archives, the compressed and uncompressed sizes are 8 bytes each.

**4.3.9.2** When compressing files, compressed and uncompressed sizes SHOULD be stored in ZIP64 format (as 8 byte values) when a file's size exceeds 0xFFFFFFFF.   However ZIP64 format MAY be used regardless of the size of a file.  When extracting, if the zip64 extended information extra field is present for the file the compressed and uncompressed sizes will be 8 byte values.  

**4.3.9.3** Although not originally assigned a signature, the value 0x08074b50 has commonly been adopted as a signature value for the data descriptor record.  Implementers SHOULD be aware that ZIP files MAY be encountered with or without this signature marking data descriptors and SHOULD account for either case when reading ZIP files to ensure compatibility.

**4.3.9.4** When writing ZIP files, implementors SHOULD include the signature value marking the data descriptor record.  When the signature is used, the fields currently defined for the data descriptor record will immediately follow the signature.

**4.3.9.5** An extensible data descriptor will be released in a future version of this APPNOTE.  This new record is intended to resolve conflicts with the use of this record going forward, and to provide better support for streamed file processing.

**4.3.9.6** When the Central Directory Encryption method is used, the data descriptor record is not required, but MAY be used. If present, and bit 3 of the general purpose bit field is set to indicate its presence, the values in fields of the data descriptor record MUST be set to binary zeros.  See the section on the Strong Encryption Specification for information. Refer to the section in this document entitled "Incorporating PKWARE Proprietary Technology into Your Product" for more information.


**4.3.11**  Archive extra data record: 

        archive extra data signature    4 bytes  (0x08064b50)
        extra field length              4 bytes
        extra field data                (variable size)

**4.3.11.1** The Archive Extra Data Record is introduced in version 6.2 of the ZIP format specification.  This record MAY be used in support of the Central Directory Encryption Feature implemented as part of the Strong Encryption Specification as described in this document. When present, this record MUST immediately precede the central directory data structure.  

**4.3.11.2** The size of this data record SHALL be included in the Size of the Central Directory field in the End of Central Directory record.  If the central directory structure is compressed, but not encrypted, the location of the start of this data record is determined using the Start of Central Directory field in the Zip64 End of Central Directory record. Refer to the section in this document entitled "Incorporating PKWARE Proprietary Technology into Your Product" for more information.

**4.3.12**  Central directory structure:

      [central directory header 1]
      .
      .
      . 
      [central directory header n]
      [digital signature] 

      File header:

        central file header signature   4 bytes  (0x02014b50)
        version made by                 2 bytes
        version needed to extract       2 bytes
        general purpose bit flag        2 bytes
        compression method              2 bytes
        last mod file time              2 bytes
        last mod file date              2 bytes
        crc-32                          4 bytes
        compressed size                 4 bytes
        uncompressed size               4 bytes
        file name length                2 bytes
        extra field length              2 bytes
        file comment length             2 bytes
        disk number start               2 bytes
        internal file attributes        2 bytes
        external file attributes        4 bytes
        relative offset of local header 4 bytes

        file name (variable size)
        extra field (variable size)
        file comment (variable size)



**4.3.14**  Zip64 end of central directory record

        zip64 end of central dir 
        signature                       4 bytes  (0x06064b50)
        size of zip64 end of central
        directory record                8 bytes
        version made by                 2 bytes
        version needed to extract       2 bytes
        number of this disk             4 bytes
        number of the disk with the 
        start of the central directory  4 bytes
        total number of entries in the
        central directory on this disk  8 bytes
        total number of entries in the
        central directory               8 bytes
        size of the central directory   8 bytes
        offset of start of central
        directory with respect to
        the starting disk number        8 bytes
        zip64 extensible data sector    (variable size)

**4.3.14.1** The value stored into the "size of zip64 end of central directory record" SHOULD be the size of the remaining record and SHOULD NOT include the leading 12 bytes.
  
      Size = SizeOfFixedFields + SizeOfVariableData - 12.

**4.3.14.2** The above record structure defines Version 1 of the zip64 end of central directory record. Version 1 was implemented in versions of this specification preceding 6.2 in support of the ZIP64 large file feature. The introduction of the Central Directory Encryption feature implemented in version 6.2 as part of the Strong Encryption Specification defines Version 2 of this record structure. Refer to the section describing the Strong Encryption Specification for details on the version 2 format for this record. Refer to the section in this document entitled "Incorporating PKWARE Proprietary Technology into Your Product" for more information applicable to use of Version 2 of this record.

**4.3.14.3** Special purpose data MAY reside in the zip64 extensible data sector field following either a V1 or V2 version of this record.  To ensure identification of this special purpose data it MUST include an identifying header block consisting of the following:

         Header ID  -  2 bytes
         Data Size  -  4 bytes

The Header ID field indicates the type of data that is in the data block that follows.

Data Size identifies the number of bytes that follow for this data block type.

**4.3.14.4** Multiple special purpose data blocks MAY be present. Each MUST be preceded by a Header ID and Data Size field.  Current mappings of Header ID values supported in this field are as defined in APPENDIX C.

**4.3.15** Zip64 end of central directory locator

      zip64 end of central dir locator 
      signature                       4 bytes  (0x07064b50)
      number of the disk with the
      start of the zip64 end of 
      central directory               4 bytes
      relative offset of the zip64
      end of central directory record 8 bytes
      total number of disks           4 bytes
        
**4.3.16**  End of central directory record

      end of central dir signature    4 bytes  (0x06054b50)
      number of this disk             2 bytes
      number of the disk with the
      start of the central directory  2 bytes
      total number of entries in the
      central directory on this disk  2 bytes
      total number of entries in
      the central directory           2 bytes
      size of the central directory   4 bytes
      offset of start of central
      directory with respect to
      the starting disk number        4 bytes
      .ZIP file comment length        2 bytes
      .ZIP file comment       (variable size)
                
4.4  Explanation of fields
--------------------------
      
**4.4.1** General notes on fields

**4.4.1.1**  All fields unless otherwise noted are unsigned and stored in Intel low-byte:high-byte, low-word:high-word order.

**4.4.1.2**  String fields are not null terminated, since the length is given explicitly.

**4.4.1.3**  The entries in the central directory MAY NOT necessarily be in the same order that files appear in the .ZIP file.

**4.4.1.4**  If one of the fields in the end of central directory record is too small to hold required data, the field SHOULD be set to -1 (0xFFFF or 0xFFFFFFFF) and the ZIP64 format record SHOULD be created.


**4.4.2** version made by (2 bytes)

**4.4.2.1** The upper byte indicates the compatibility of the file attribute information.  If the external file attributes are compatible with MS-DOS and can be read by PKZIP for DOS version 2.04g then this value will be zero.  If these attributes are not compatible, then this value will identify the host system on which the attributes are compatible.  Software can use this information to determine the line record format for text files etc.  

**4.4.2.2** The current mappings are:

         0 - MS-DOS and OS/2 (FAT / VFAT / FAT32 file systems)
         3 - UNIX                      
         7 - Macintosh                 
        10 - Windows NTFS
        19 - OS X (Darwin)            
        20 thru 255 - unused

**4.4.2.3** The lower byte indicates the ZIP specification version (the version of this document) supported by the software used to encode the file.  The value/10 indicates the major version number, and the value mod 10 is the minor version number.  

**4.4.3** version needed to extract (2 bytes)

**4.4.3.1** The minimum supported ZIP specification version needed to extract the file, mapped as above.  This value is based on the specific format features a ZIP program MUST support to be able to extract the file.  If multiple features are applied to a file, the minimum version MUST be set to the feature having the highest value. New features or feature changes affecting the published format specification will be implemented using higher version numbers than the last published value to avoid conflict.

**4.4.3.2** Current minimum feature versions are as defined below:

```
    0x0A,0x00  1.0 - Default value
    0x14,0x00  2.0 - File is compressed using Deflate compression
    0x2D,0x00  4.5 - File uses ZIP64 format extensions (version 1 only)
```

When using ZIP64 extensions, the corresponding value in the zip64 end of central directory record MUST also be set. This field SHOULD be set appropriately to indicate whether Version 1 or Version 2 format is in use. 


**4.4.4** general purpose bit flag: (2 bytes)

    Bit 0: 0

    Bit 2  Bit 1
    0      0    Normal (-en) compression option was used.
    0      1    Maximum (-exx/-ex) compression option was used.
    1      0    Fast (-ef) compression option was used.
    1      1    Super Fast (-es) compression option was used.


        Bit 3: If this bit is set, the fields crc-32, compressed 
               size and uncompressed size are set to zero in the 
               local header.  The correct values are put in the 
               data descriptor immediately following the compressed
               data.  (Note: PKZIP version 2.04g for DOS only 
               recognizes this bit for method 8 compression, newer 
               versions of PKZIP recognize this bit for any 
               compression method.)


        Bit 4 : 0 
        Bit 5 : 0
        Bit 6 : 0
        Bit 7 : 0
        Bit 8 : 0
        Bit 9 : 0
        Bit 10: 0

        Bit 11: Language encoding flag (EFS).  If this bit is set,
                the filename and comment fields for this file
                MUST be encoded using UTF-8. (see APPENDIX D)
```
Bit 11 should be set. If the value of any byte in the file name or file comment is greater than 0x7F, bit 11 shall be set.

If bit 11 is set the file names and comment fields for the document container file shall be Unicode strings encoded using the UTF-8 encoding scheme as specified in ISO/IEC 10646:2014, Annex D.
```


        Bit 12: 0
        Bit 13: 0
        Bit 14: 0
        Bit 15: 0

4.4.5 compression method: (2 bytes)

        0 - The file is stored (no compression)
        8 - The file is Deflated

4.4.6 date and time fields: (2 bytes each)

       The date and time are encoded in standard MS-DOS format.
       If input came from standard input, the date and time are
       those at which compression was started for this data. 
       If encrypting the central directory and general purpose bit 
       flag 13 is set indicating masking, the value stored in the 
       Local Header will be zero. MS-DOS time format is different
       from more commonly used computer time formats such as 
       UTC. For example, MS-DOS uses year values relative to 1980
       and 2 second precision.

4.4.7 CRC-32: (4 bytes)

       The CRC-32 algorithm was generously contributed by
       David Schwaderer and can be found in his excellent
       book "C Programmers Guide to NetBIOS" published by
       Howard W. Sams & Co. Inc.  The 'magic number' for
       the CRC is 0xdebb20e3.  The proper CRC pre and post
       conditioning is used, meaning that the CRC register
       is pre-conditioned with all ones (a starting value
       of 0xffffffff) and the value is post-conditioned by
       taking the one's complement of the CRC residual.
       If bit 3 of the general purpose flag is set, this
       field is set to zero in the local header and the correct
       value is put in the data descriptor and in the central
       directory. When encrypting the central directory, if the
       local header is not in ZIP64 format and general purpose 
       bit flag 13 is set indicating masking, the value stored 
       in the Local Header will be zero. 

4.4.8 compressed size: (4 bytes)
4.4.9 uncompressed size: (4 bytes)

       The size of the file compressed (4.4.8) and uncompressed,
       (4.4.9) respectively.  When a decryption header is present it 
       will be placed in front of the file data and the value of the
       compressed file size will include the bytes of the decryption
       header.  If bit 3 of the general purpose bit flag is set, 
       these fields are set to zero in the local header and the 
       correct values are put in the data descriptor and
       in the central directory.  If an archive is in ZIP64 format
       and the value in this field is 0xFFFFFFFF, the size will be
       in the corresponding 8 byte ZIP64 extended information 
       extra field.  When encrypting the central directory, if the
       local header is not in ZIP64 format and general purpose bit 
       flag 13 is set indicating masking, the value stored for the 
       uncompressed size in the Local Header will be zero. 

4.4.10 file name length: (2 bytes)
4.4.11 extra field length: (2 bytes)
4.4.12 file comment length: (2 bytes)

       The length of the file name, extra field, and comment
       fields respectively.  The combined length of any
       directory record and these three fields SHOULD NOT
       generally exceed 65,535 bytes.  If input came from standard
       input, the file name length is set to zero.  


4.4.13 disk number start: (2 bytes)

       The number of the disk on which this file begins.  If an 
       archive is in ZIP64 format and the value in this field is 
       0xFFFF, the size will be in the corresponding 4 byte zip64 
       extended information extra field.

4.4.14 internal file attributes: (2 bytes)

       Bits 1 and 2 are reserved for use by PKWARE.

       4.4.14.1 The lowest bit of this field indicates, if set, 
       that the file is apparently an ASCII or text file.  If not
       set, that the file apparently contains binary data.
       The remaining bits are unused in version 1.0.

       4.4.14.2 The 0x0002 bit of this field indicates, if set, that 
       a 4 byte variable record length control field precedes each 
       logical record indicating the length of the record. The 
       record length control field is stored in little-endian byte
       order.  This flag is independent of text control characters, 
       and if used in conjunction with text data, includes any 
       control characters in the total length of the record. This 
       value is provided for mainframe data transfer support.

4.4.15 external file attributes: (4 bytes)

       The mapping of the external attributes is
       host-system dependent (see 'version made by').  For
       MS-DOS, the low order byte is the MS-DOS directory
       attribute byte.  If input came from standard input, this
       field is set to zero.

4.4.16 relative offset of local header: (4 bytes)

       This is the offset from the start of the first disk on
       which this file appears, to where the local header SHOULD
       be found.  If an archive is in ZIP64 format and the value
       in this field is 0xFFFFFFFF, the size will be in the 
       corresponding 8 byte zip64 extended information extra field.

4.4.17 file name: (Variable)

       4.4.17.1 The name of the file, with optional relative path.
       The path stored MUST NOT contain a drive or
       device letter, or a leading slash.  All slashes
       MUST be forward slashes '/' as opposed to
       backwards slashes '\' for compatibility with Amiga
       and UNIX file systems etc.  If input came from standard
       input, there is no file name field.  

       4.4.17.2 If using the Central Directory Encryption Feature and 
       general purpose bit flag 13 is set indicating masking, the file 
       name stored in the Local Header will not be the actual file name.  
       A masking value consisting of a unique hexadecimal value will 
       be stored.  This value will be sequentially incremented for each 
       file in the archive. See the section on the Strong Encryption 
       Specification for details on retrieving the encrypted file name. 
       Refer to the section in this document entitled "Incorporating PKWARE 
       Proprietary Technology into Your Product" for more information.


4.4.18 file comment: (Variable)

       The comment for this file.

4.4.19 number of this disk: (2 bytes)

       The number of this disk, which contains central
       directory end record. If an archive is in ZIP64 format
       and the value in this field is 0xFFFF, the size will 
       be in the corresponding 4 byte zip64 end of central 
       directory field.


4.4.20 number of the disk with the start of the central
            directory: (2 bytes)

       The number of the disk on which the central
       directory starts. If an archive is in ZIP64 format
       and the value in this field is 0xFFFF, the size will 
       be in the corresponding 4 byte zip64 end of central 
       directory field.

4.4.21 total number of entries in the central dir on this disk: (2 bytes)

      The number of central directory entries on this disk.
      If an archive is in ZIP64 format and the value in 
      this field is 0xFFFF, the size will be in the 
      corresponding 8 byte zip64 end of central 
      directory field.

4.4.22 total number of entries in the central dir: (2 bytes)

      The total number of files in the .ZIP file. If an 
      archive is in ZIP64 format and the value in this field
      is 0xFFFF, the size will be in the corresponding 8 byte 
      zip64 end of central directory field.

4.4.23 size of the central directory: (4 bytes)

      The size (in bytes) of the entire central directory.
      If an archive is in ZIP64 format and the value in 
      this field is 0xFFFFFFFF, the size will be in the 
      corresponding 8 byte zip64 end of central 
      directory field.

4.4.24 offset of start of central directory with respect to the starting disk number:  (4 bytes)

      Offset of the start of the central directory on the
      disk on which the central directory starts. If an 
      archive is in ZIP64 format and the value in this 
      field is 0xFFFFFFFF, the size will be in the 
      corresponding 8 byte zip64 end of central 
      directory field.

4.4.25 .ZIP file comment length: (2 bytes)

      The length of the comment for this .ZIP file.

4.4.26 .ZIP file comment: (Variable)

      The comment for this .ZIP file.  ZIP file comment data
      is stored unsecured.  No encryption or data authentication
      is applied to this area at this time.  Confidential information
      SHOULD NOT be stored in this section.

4.4.27 zip64 extensible data sector    (variable size)

      (currently reserved for use by PKWARE)


4.4.28 extra field: (Variable)

     This SHOULD be used for storage expansion.  If additional 
     information needs to be stored within a ZIP file for special 
     application or platform needs, it SHOULD be stored here.  
     Programs supporting earlier versions of this specification can 
     then safely skip the file, and find the next file or header.  
     This field will be 0 length in version 1.0.  

     Existing extra fields are defined in the section
     Extensible data fields that follows.

4.5 Extensible data fields
--------------------------

   4.5.1 In order to allow different programs and different types
   of information to be stored in the 'extra' field in .ZIP
   files, the following structure MUST be used for all
   programs storing data in this field:

       header1+data1 + header2+data2 . . .

   Each header MUST consist of:

       Header ID - 2 bytes
       Data Size - 2 bytes

   Note: all fields stored in Intel low-byte/high-byte order.

   The Header ID field indicates the type of data that is in
   the following data block.

   Header IDs of 0 thru 31 are reserved for use by PKWARE.
   The remaining IDs can be used by third party vendors for
   proprietary usage.

   4.5.2 The current Header ID mappings defined by PKWARE are:

      0x0001        Zip64 extended information extra field
      0x0007        AV Info
      0x0008        Reserved for extended language encoding data (PFS)
                    (see APPENDIX D)
      0x0009        OS/2
      0x000a        NTFS 
      0x000c        OpenVMS
      0x000d        UNIX
      0x000e        Reserved for file stream and fork descriptors
      0x000f        Patch Descriptor
      0x0014        PKCS#7 Store for X.509 Certificates
      0x0015        X.509 Certificate ID and Signature for 
                    individual file
      0x0016        X.509 Certificate ID for Central Directory
      0x0017        Strong Encryption Header
      0x0018        Record Management Controls
      0x0019        PKCS#7 Encryption Recipient Certificate List
      0x0020        Reserved for Timestamp record
      0x0021        Policy Decryption Key Record
      0x0022        Smartcrypt Key Provider Record
      0x0023        Smartcrypt Policy Key Data Record
      0x0065        IBM S/390 (Z390), AS/400 (I400) attributes 
                    - uncompressed
      0x0066        Reserved for IBM S/390 (Z390), AS/400 (I400) 
                    attributes - compressed
      0x4690        POSZIP 4690 (reserved) 


   4.5.3 -Zip64 Extended Information Extra Field (0x0001):

      The following is the layout of the zip64 extended 
      information "extra" block. If one of the size or
      offset fields in the Local or Central directory
      record is too small to hold the required data,
      a Zip64 extended information record is created.
      The order of the fields in the zip64 extended 
      information record is fixed, but the fields MUST
      only appear if the corresponding Local or Central
      directory record field is set to 0xFFFF or 0xFFFFFFFF.

      Note: all fields stored in Intel low-byte/high-byte order.

        Value      Size       Description
        -----      ----       -----------
(ZIP64) 0x0001     2 bytes    Tag for this "extra" block type
        Size       2 bytes    Size of this "extra" block
        Original 
        Size       8 bytes    Original uncompressed file size
        Compressed
        Size       8 bytes    Size of compressed data
        Relative Header
        Offset     8 bytes    Offset of local header record
        Disk Start
        Number     4 bytes    Number of the disk on which
                              this file starts 

      This entry in the Local header MUST include BOTH original
      and compressed file size fields. If encrypting the 
      central directory and bit 13 of the general purpose bit
      flag is set indicating masking, the value stored in the
      Local Header for the original file size will be zero.


   4.5.4 -OS/2 Extra Field (0x0009):

      The following is the layout of the OS/2 attributes "extra" 
      block.  (Last Revision  09/05/95)

      Note: all fields stored in Intel low-byte/high-byte order.

        Value       Size          Description
        -----       ----          -----------
(OS/2)  0x0009      2 bytes       Tag for this "extra" block type
        TSize       2 bytes       Size for the following data block
        BSize       4 bytes       Uncompressed Block Size
        CType       2 bytes       Compression type
        EACRC       4 bytes       CRC value for uncompress block
        (var)       variable      Compressed block

      The OS/2 extended attribute structure (FEA2LIST) is 
      compressed and then stored in its entirety within this 
      structure.  There will only ever be one "block" of data in 
      VarFields[].

   4.5.5 -NTFS Extra Field (0x000a):

      The following is the layout of the NTFS attributes 
      "extra" block. (Note: At this time the Mtime, Atime
      and Ctime values MAY be used on any WIN32 system.)  

      Note: all fields stored in Intel low-byte/high-byte order.

        Value      Size       Description
        -----      ----       -----------
(NTFS)  0x000a     2 bytes    Tag for this "extra" block type
        TSize      2 bytes    Size of the total "extra" block
        Reserved   4 bytes    Reserved for future use
        Tag1       2 bytes    NTFS attribute tag value #1
        Size1      2 bytes    Size of attribute #1, in bytes
        (var)      Size1      Attribute #1 data
         .
         .
         .
         TagN       2 bytes    NTFS attribute tag value #N
         SizeN      2 bytes    Size of attribute #N, in bytes
         (var)      SizeN      Attribute #N data

       For NTFS, values for Tag1 through TagN are as follows:
       (currently only one set of attributes is defined for NTFS)

         Tag        Size       Description
         -----      ----       -----------
         0x0001     2 bytes    Tag for attribute #1 
         Size1      2 bytes    Size of attribute #1, in bytes
         Mtime      8 bytes    File last modification time
         Atime      8 bytes    File last access time
         Ctime      8 bytes    File creation time

   4.5.6 -OpenVMS Extra Field (0x000c):

       The following is the layout of the OpenVMS attributes 
       "extra" block.

       Note: all fields stored in Intel low-byte/high-byte order.

         Value      Size       Description
         -----      ----       -----------
 (VMS)   0x000c     2 bytes    Tag for this "extra" block type
         TSize      2 bytes    Size of the total "extra" block
         CRC        4 bytes    32-bit CRC for remainder of the block
         Tag1       2 bytes    OpenVMS attribute tag value #1
         Size1      2 bytes    Size of attribute #1, in bytes
         (var)      Size1      Attribute #1 data
         .
         .
         .
         TagN       2 bytes    OpenVMS attribute tag value #N
         SizeN      2 bytes    Size of attribute #N, in bytes
         (var)      SizeN      Attribute #N data

       OpenVMS Extra Field Rules:

          4.5.6.1. There will be one or more attributes present, which 
          will each be preceded by the above TagX & SizeX values.  
          These values are identical to the ATR$C_XXXX and ATR$S_XXXX 
          constants which are defined in ATR.H under OpenVMS C.  Neither 
          of these values will ever be zero.

          4.5.6.2. No word alignment or padding is performed.

          4.5.6.3. A well-behaved PKZIP/OpenVMS program SHOULD NOT produce
          more than one sub-block with the same TagX value.  Also, there MUST 
          NOT be more than one "extra" block of type 0x000c in a particular 
          directory record.

   4.5.7 -UNIX Extra Field (0x000d):

        The following is the layout of the UNIX "extra" block.
        Note: all fields are stored in Intel low-byte/high-byte 
        order.

        Value       Size          Description
        -----       ----          -----------
(UNIX)  0x000d      2 bytes       Tag for this "extra" block type
        TSize       2 bytes       Size for the following data block
        Atime       4 bytes       File last access time
        Mtime       4 bytes       File last modification time
        Uid         2 bytes       File user ID
        Gid         2 bytes       File group ID
        (var)       variable      Variable length data field

        The variable length data field will contain file type 
        specific data.  Currently the only values allowed are
        the original "linked to" file names for hard or symbolic 
        links, and the major and minor device node numbers for
        character and block device nodes.  Since device nodes
        cannot be either symbolic or hard links, only one set of
        variable length data is stored.  Link files will have the
        name of the original file stored.  This name is NOT NULL
        terminated.  Its size can be determined by checking TSize -
        12.  Device entries will have eight bytes stored as two 4
        byte entries (in little endian format).  The first entry
        will be the major device number, and the second the minor
        device number.
                          
   4.5.8 -PATCH Descriptor Extra Field (0x000f):

        4.5.8.1 The following is the layout of the Patch Descriptor 
        "extra" block.

        Note: all fields stored in Intel low-byte/high-byte order.

        Value     Size     Description
        -----     ----     -----------
(Patch) 0x000f    2 bytes  Tag for this "extra" block type
        TSize     2 bytes  Size of the total "extra" block
        Version   2 bytes  Version of the descriptor
        Flags     4 bytes  Actions and reactions (see below) 
        OldSize   4 bytes  Size of the file about to be patched 
        OldCRC    4 bytes  32-bit CRC of the file to be patched 
        NewSize   4 bytes  Size of the resulting file 
        NewCRC    4 bytes  32-bit CRC of the resulting file 

        4.5.8.2 Actions and reactions

        Bits          Description
        ----          ----------------
        0             Use for auto detection
        1             Treat as a self-patch
        2-3           RESERVED
        4-5           Action (see below)
        6-7           RESERVED
        8-9           Reaction (see below) to absent file 
        10-11         Reaction (see below) to newer file
        12-13         Reaction (see below) to unknown file
        14-15         RESERVED
        16-31         RESERVED

           4.5.8.2.1 Actions

           Action       Value
           ------       ----- 
           none         0
           add          1
           delete       2
           patch        3

           4.5.8.2.2 Reactions
        
           Reaction     Value
           --------     -----
           ask          0
           skip         1
           ignore       2
           fail         3

        4.5.8.3 Patch support is provided by PKPatchMaker(tm) technology 
        and is covered under U.S. Patents and Patents Pending. The use or 
        implementation in a product of certain technological aspects set
        forth in the current APPNOTE, including those with regard to 
        strong encryption or patching requires a license from PKWARE.  
        Refer to the section in this document entitled "Incorporating 
        PKWARE Proprietary Technology into Your Product" for more 
        information. 

   4.5.9 -PKCS#7 Store for X.509 Certificates (0x0014):

        This field MUST contain information about each of the certificates 
        files MAY be signed with. When the Central Directory Encryption 
        feature is enabled for a ZIP file, this record will appear in 
        the Archive Extra Data Record, otherwise it will appear in the 
        first central directory record and will be ignored in any 
        other record.  

                          
        Note: all fields stored in Intel low-byte/high-byte order.

        Value     Size     Description
        -----     ----     -----------
(Store) 0x0014    2 bytes  Tag for this "extra" block type
        TSize     2 bytes  Size of the store data
        TData     TSize    Data about the store


   4.5.10 -X.509 Certificate ID and Signature for individual file (0x0015):

        This field contains the information about which certificate in 
        the PKCS#7 store was used to sign a particular file. It also 
        contains the signature data. This field can appear multiple 
        times, but can only appear once per certificate.

        Note: all fields stored in Intel low-byte/high-byte order.

        Value     Size     Description
        -----     ----     -----------
(CID)   0x0015    2 bytes  Tag for this "extra" block type
        TSize     2 bytes  Size of data that follows
        TData     TSize    Signature Data

   4.5.11 -X.509 Certificate ID and Signature for central directory (0x0016):

        This field contains the information about which certificate in 
        the PKCS#7 store was used to sign the central directory structure.
        When the Central Directory Encryption feature is enabled for a 
        ZIP file, this record will appear in the Archive Extra Data Record, 
        otherwise it will appear in the first central directory record.

        Note: all fields stored in Intel low-byte/high-byte order.

        Value     Size     Description
        -----     ----     -----------
(CDID)  0x0016    2 bytes  Tag for this "extra" block type
        TSize     2 bytes  Size of data that follows
        TData     TSize    Data

   4.5.12 -Strong Encryption Header (0x0017):

        Value     Size     Description
        -----     ----     -----------
        0x0017    2 bytes  Tag for this "extra" block type
        TSize     2 bytes  Size of data that follows
        Format    2 bytes  Format definition for this record
        AlgID     2 bytes  Encryption algorithm identifier
        Bitlen    2 bytes  Bit length of encryption key
        Flags     2 bytes  Processing flags
        CertData  TSize-8  Certificate decryption extra field data
                           (refer to the explanation for CertData
                            in the section describing the 
                            Certificate Processing Method under 
                            the Strong Encryption Specification)

        See the section describing the Strong Encryption Specification 
        for details.  Refer to the section in this document entitled 
        "Incorporating PKWARE Proprietary Technology into Your Product" 
        for more information.

   4.5.13 -Record Management Controls (0x0018):

          Value     Size     Description
          -----     ----     -----------
(Rec-CTL) 0x0018    2 bytes  Tag for this "extra" block type
          CSize     2 bytes  Size of total extra block data
          Tag1      2 bytes  Record control attribute 1
          Size1     2 bytes  Size of attribute 1, in bytes
          Data1     Size1    Attribute 1 data
          .
          .
          .
          TagN      2 bytes  Record control attribute N
          SizeN     2 bytes  Size of attribute N, in bytes
          DataN     SizeN    Attribute N data


   4.5.14 -PKCS#7 Encryption Recipient Certificate List (0x0019): 

        This field MAY contain information about each of the certificates
        used in encryption processing and it can be used to identify who is
        allowed to decrypt encrypted files.  This field SHOULD only appear 
        in the archive extra data record. This field is not required and 
        serves only to aid archive modifications by preserving public 
        encryption key data. Individual security requirements may dictate 
        that this data be omitted to deter information exposure.

        Note: all fields stored in Intel low-byte/high-byte order.

         Value     Size     Description
         -----     ----     -----------
(CStore) 0x0019    2 bytes  Tag for this "extra" block type
         TSize     2 bytes  Size of the store data
         TData     TSize    Data about the store

         TData:

         Value     Size     Description
         -----     ----     -----------
         Version   2 bytes  Format version number - MUST be 0x0001 at this time
         CStore    (var)    PKCS#7 data blob

         See the section describing the Strong Encryption Specification 
         for details.  Refer to the section in this document entitled 
         "Incorporating PKWARE Proprietary Technology into Your Product" 
         for more information.

   4.5.15 -MVS Extra Field (0x0065):

        The following is the layout of the MVS "extra" block.
        Note: Some fields are stored in Big Endian format.
        All text is in EBCDIC format unless otherwise specified.
Value     Size      Description
        -----     ----      -----------
(MVS)   0x0065    2 bytes   Tag for this "extra" block type
        TSize     2 bytes   Size for the following data block
        ID        4 bytes   EBCDIC "Z390" 0xE9F3F9F0 or
                            "T4MV" for TargetFour
        (var)     TSize-4   Attribute data (see APPENDIX B)


   4.5.16 -OS/400 Extra Field (0x0065):

        The following is the layout of the OS/400 "extra" block.
        Note: Some fields are stored in Big Endian format.
        All text is in EBCDIC format unless otherwise specified.

        Value     Size       Description
        -----     ----       -----------
(OS400) 0x0065    2 bytes    Tag for this "extra" block type
        TSize     2 bytes    Size for the following data block
        ID        4 bytes    EBCDIC "I400" 0xC9F4F0F0 or
                             "T4MV" for TargetFour
        (var)     TSize-4    Attribute data (see APPENDIX A)

   4.5.17 -Policy Decryption Key Record Extra Field (0x0021):

        The following is the layout of the Policy Decryption Key "extra" block.
        TData is a variable length, variable content field.  It holds
        information about encryptions and/or encryption key sources.
        Contact PKWARE for information on current TData structures.
        Information in this "extra" block may aternatively be placed
        within comment fields.  Refer to the section in this document 
        entitled "Incorporating PKWARE Proprietary Technology into Your 
        Product" for more information.

        Value     Size       Description
        -----     ----       -----------
        0x0021    2 bytes    Tag for this "extra" block type
        TSize     2 bytes    Size for the following data block
        TData     TSize      Data about the key

   4.5.18 -Key Provider Record Extra Field (0x0022):

        The following is the layout of the Key Provider "extra" block.
        TData is a variable length, variable content field.  It holds
        information about encryptions and/or encryption key sources.
        Contact PKWARE for information on current TData structures.
        Information in this "extra" block may aternatively be placed
        within comment fields.  Refer to the section in this document 
        entitled "Incorporating PKWARE Proprietary Technology into Your 
        Product" for more information.

        Value     Size       Description
        -----     ----       -----------
        0x0022    2 bytes    Tag for this "extra" block type
        TSize     2 bytes    Size for the following data block
        TData     TSize      Data about the key

   4.5.19 -Policy Key Data Record Record Extra Field (0x0023):

        The following is the layout of the Policy Key Data "extra" block.
        TData is a variable length, variable content field.  It holds
        information about encryptions and/or encryption key sources.
        Contact PKWARE for information on current TData structures.
        Information in this "extra" block may aternatively be placed
        within comment fields.  Refer to the section in this document 
        entitled "Incorporating PKWARE Proprietary Technology into Your 
        Product" for more information.

        Value     Size       Description
        -----     ----       -----------
        0x0023    2 bytes    Tag for this "extra" block type
        TSize     2 bytes    Size for the following data block
        TData     TSize      Data about the key

4.6 Third Party Mappings
------------------------
                 
   4.6.1 Third party mappings commonly used are:

          0x07c8        Macintosh
          0x2605        ZipIt Macintosh
          0x2705        ZipIt Macintosh 1.3.5+
          0x2805        ZipIt Macintosh 1.3.5+
          0x334d        Info-ZIP Macintosh
          0x4341        Acorn/SparkFS 
          0x4453        Windows NT security descriptor (binary ACL)
          0x4704        VM/CMS
          0x470f        MVS
          0x4b46        FWKCS MD5 (see below)
          0x4c41        OS/2 access control list (text ACL)
          0x4d49        Info-ZIP OpenVMS
          0x4f4c        Xceed original location extra field
          0x5356        AOS/VS (ACL)
          0x5455        extended timestamp
          0x554e        Xceed unicode extra field
          0x5855        Info-ZIP UNIX (original, also OS/2, NT, etc)
          0x6375        Info-ZIP Unicode Comment Extra Field
          0x6542        BeOS/BeBox
          0x7075        Info-ZIP Unicode Path Extra Field
          0x756e        ASi UNIX
          0x7855        Info-ZIP UNIX (new)
          0xa220        Microsoft Open Packaging Growth Hint
          0xfd4a        SMS/QDOS
          0x9901        AE-x encryption structure (see APPENDIX E)
          0x9902        unknown


   Detailed descriptions of Extra Fields defined by third 
   party mappings will be documented as information on
   these data structures is made available to PKWARE.  
   PKWARE does not guarantee the accuracy of any published
   third party data.

   4.6.2 Third-party Extra Fields MUST include a Header ID using
   the format defined in the section of this document 
   titled Extensible Data Fields (section 4.5).

   The Data Size field indicates the size of the following
   data block. Programs can use this value to skip to the
   next header block, passing over any data blocks that are
   not of interest.

   Note: As stated above, the size of the entire .ZIP file
         header, including the file name, comment, and extra
         field SHOULD NOT exceed 64K in size.

   4.6.3 In case two different programs appropriate the same
   Header ID value, it is strongly recommended that each
   program SHOULD place a unique signature of at least two bytes in
   size (and preferably 4 bytes or bigger) at the start of
   each data area.  Every program SHOULD verify that its
   unique signature is present, in addition to the Header ID
   value being correct, before assuming that it is a block of
   known type.
         
   Third-party Mappings:
          
   4.6.4 -ZipIt Macintosh Extra Field (long) (0x2605):

      The following is the layout of the ZipIt extra block 
      for Macintosh. The local-header and central-header versions 
      are identical. This block MUST be present if the file is 
      stored MacBinary-encoded and it SHOULD NOT be used if the file 
      is not stored MacBinary-encoded.

          Value         Size        Description
          -----         ----        -----------
  (Mac2)  0x2605        Short       tag for this extra block type
          TSize         Short       total data size for this block
          "ZPIT"        beLong      extra-field signature
          FnLen         Byte        length of FileName
          FileName      variable    full Macintosh filename
          FileType      Byte[4]     four-byte Mac file type string
          Creator       Byte[4]     four-byte Mac creator string


   4.6.5 -ZipIt Macintosh Extra Field (short, for files) (0x2705):

      The following is the layout of a shortened variant of the
      ZipIt extra block for Macintosh (without "full name" entry).
      This variant is used by ZipIt 1.3.5 and newer for entries of
      files (not directories) that do not have a MacBinary encoded
      file. The local-header and central-header versions are identical.

         Value         Size        Description
         -----         ----        -----------
 (Mac2b) 0x2705        Short       tag for this extra block type
         TSize         Short       total data size for this block (12)
         "ZPIT"        beLong      extra-field signature
         FileType      Byte[4]     four-byte Mac file type string
         Creator       Byte[4]     four-byte Mac creator string
         fdFlags       beShort     attributes from FInfo.frFlags,
                                   MAY be omitted
         0x0000        beShort     reserved, MAY be omitted


   4.6.6 -ZipIt Macintosh Extra Field (short, for directories) (0x2805):

      The following is the layout of a shortened variant of the
      ZipIt extra block for Macintosh used only for directory
      entries. This variant is used by ZipIt 1.3.5 and newer to 
      save some optional Mac-specific information about directories.
      The local-header and central-header versions are identical.

         Value         Size        Description
         -----         ----        -----------
 (Mac2c) 0x2805        Short       tag for this extra block type
         TSize         Short       total data size for this block (12)
         "ZPIT"        beLong      extra-field signature
         frFlags       beShort     attributes from DInfo.frFlags, MAY
                                   be omitted
         View          beShort     ZipIt view flag, MAY be omitted


     The View field specifies ZipIt-internal settings as follows:

     Bits of the Flags:
        bit 0           if set, the folder is shown expanded (open)
                        when the archive contents are viewed in ZipIt.
        bits 1-15       reserved, zero;


   4.6.7 -FWKCS MD5 Extra Field (0x4b46):

      The FWKCS Contents_Signature System, used in
      automatically identifying files independent of file name,
      optionally adds and uses an extra field to support the
      rapid creation of an enhanced contents_signature:

              Header ID = 0x4b46
              Data Size = 0x0013
              Preface   = 'M','D','5'
              followed by 16 bytes containing the uncompressed file's
              128_bit MD5 hash(1), low byte first.

      When FWKCS revises a .ZIP file central directory to add
      this extra field for a file, it also replaces the
      central directory entry for that file's uncompressed
      file length with a measured value.

      FWKCS provides an option to strip this extra field, if
      present, from a .ZIP file central directory. In adding
      this extra field, FWKCS preserves .ZIP file Authenticity
      Verification; if stripping this extra field, FWKCS
      preserves all versions of AV through PKZIP version 2.04g.

      FWKCS, and FWKCS Contents_Signature System, are
      trademarks of Frederick W. Kantor.

      (1) R. Rivest, RFC1321.TXT, MIT Laboratory for Computer
          Science and RSA Data Security, Inc., April 1992.
          ll.76-77: "The MD5 algorithm is being placed in the
          public domain for review and possible adoption as a
          standard."


   4.6.8 -Info-ZIP Unicode Comment Extra Field (0x6375):

      Stores the UTF-8 version of the file comment as stored in the
      central directory header. (Last Revision 20070912)

         Value         Size        Description
         -----         ----        -----------
  (UCom) 0x6375        Short       tag for this extra block type ("uc")
         TSize         Short       total data size for this block
         Version       1 byte      version of this extra field, currently 1
         ComCRC32      4 bytes     Comment Field CRC32 Checksum
         UnicodeCom    Variable    UTF-8 version of the entry comment

       Currently Version is set to the number 1.  If there is a need
       to change this field, the version will be incremented.  Changes
       MAY NOT be backward compatible so this extra field SHOULD NOT be
       used if the version is not recognized.

       The ComCRC32 is the standard zip CRC32 checksum of the File Comment
       field in the central directory header.  This is used to verify that
       the comment field has not changed since the Unicode Comment extra field
       was created.  This can happen if a utility changes the File Comment 
       field but does not update the UTF-8 Comment extra field.  If the CRC 
       check fails, this Unicode Comment extra field SHOULD be ignored and 
       the File Comment field in the header SHOULD be used instead.

       The UnicodeCom field is the UTF-8 version of the File Comment field
       in the header.  As UnicodeCom is defined to be UTF-8, no UTF-8 byte
       order mark (BOM) is used.  The length of this field is determined by
       subtracting the size of the previous fields from TSize.  If both the
       File Name and Comment fields are UTF-8, the new General Purpose Bit
       Flag, bit 11 (Language encoding flag (EFS)), can be used to indicate
       both the header File Name and Comment fields are UTF-8 and, in this
       case, the Unicode Path and Unicode Comment extra fields are not
       needed and SHOULD NOT be created.  Note that, for backward
       compatibility, bit 11 SHOULD only be used if the native character set
       of the paths and comments being zipped up are already in UTF-8. It is
       expected that the same file comment storage method, either general
       purpose bit 11 or extra fields, be used in both the Local and Central
       Directory Header for a file.


   4.6.9 -Info-ZIP Unicode Path Extra Field (0x7075):

       Stores the UTF-8 version of the file name field as stored in the
       local header and central directory header. (Last Revision 20070912)

         Value         Size        Description
         -----         ----        -----------
 (UPath) 0x7075        Short       tag for this extra block type ("up")
         TSize         Short       total data size for this block
         Version       1 byte      version of this extra field, currently 1
         NameCRC32     4 bytes     File Name Field CRC32 Checksum
         UnicodeName   Variable    UTF-8 version of the entry File Name

      Currently Version is set to the number 1.  If there is a need
      to change this field, the version will be incremented.  Changes
      MAY NOT be backward compatible so this extra field SHOULD NOT be
      used if the version is not recognized.

      The NameCRC32 is the standard zip CRC32 checksum of the File Name
      field in the header.  This is used to verify that the header
      File Name field has not changed since the Unicode Path extra field
      was created.  This can happen if a utility renames the File Name but
      does not update the UTF-8 path extra field.  If the CRC check fails,
      this UTF-8 Path Extra Field SHOULD be ignored and the File Name field
      in the header SHOULD be used instead.

      The UnicodeName is the UTF-8 version of the contents of the File Name
      field in the header.  As UnicodeName is defined to be UTF-8, no UTF-8
      byte order mark (BOM) is used.  The length of this field is determined
      by subtracting the size of the previous fields from TSize.  If both
      the File Name and Comment fields are UTF-8, the new General Purpose
      Bit Flag, bit 11 (Language encoding flag (EFS)), can be used to
      indicate that both the header File Name and Comment fields are UTF-8
      and, in this case, the Unicode Path and Unicode Comment extra fields
      are not needed and SHOULD NOT be created.  Note that, for backward
      compatibility, bit 11 SHOULD only be used if the native character set
      of the paths and comments being zipped up are already in UTF-8. It is
      expected that the same file name storage method, either general
      purpose bit 11 or extra fields, be used in both the Local and Central
      Directory Header for a file.
 

   4.6.10 -Microsoft Open Packaging Growth Hint (0xa220):

          Value         Size        Description
          -----         ----        -----------
          0xa220        Short       tag for this extra block type
          TSize         Short       size of Sig + PadVal + Padding
          Sig           Short       verification signature (A028)
          PadVal        Short       Initial padding value
          Padding       variable    filled with NULL characters


5.0 Explanation of compression methods
--------------------------------------


5.5 Deflating - Method 8
------------------------

```
Files compressed using this method shall use the mechanisms specified in IETF RFC 1951
```





APPENDIX C - Zip64 Extensible Data Sector Mappings 
---------------------------------------------------

         -Z390   Extra Field:

          The following is the general layout of the attributes for the 
          ZIP 64 "extra" block for extended tape operations.  

          Note: some fields stored in Big Endian format.  All text is 
          in EBCDIC format unless otherwise specified.

          Value       Size          Description
          -----       ----          -----------
  (Z390)  0x0065      2 bytes       Tag for this "extra" block type
          Size        4 bytes       Size for the following data block
          Tag         4 bytes       EBCDIC "Z390"
          Length71    2 bytes       Big Endian
          Subcode71   2 bytes       Enote type code
          FMEPos      1 byte
          Length72    2 bytes       Big Endian
          Subcode72   2 bytes       Unit type code
          Unit        1 byte        Unit
          Length73    2 bytes       Big Endian
          Subcode73   2 bytes       Volume1 type code
          FirstVol    1 byte        Volume
          Length74    2 bytes       Big Endian
          Subcode74   2 bytes       FirstVol file sequence
          FileSeq     2 bytes       Sequence 

APPENDIX D - Language Encoding (EFS)
------------------------------------

D.1 The ZIP format has historically supported only the original IBM PC character 
encoding set, commonly referred to as IBM Code Page 437.  This limits storing 
file name characters to only those within the original MS-DOS range of values 
and does not properly support file names in other character encodings, or 
languages. To address this limitation, this specification will support the 
following change. 

D.2 If general purpose bit 11 is unset, the file name and comment SHOULD conform 
to the original ZIP character encoding.  If general purpose bit 11 is set, the 
filename and comment MUST support The Unicode Standard, Version 4.1.0 or 
greater using the character encoding form defined by the UTF-8 storage 
specification.  The Unicode Standard is published by the The Unicode
Consortium (www.unicode.org).  UTF-8 encoded data stored within ZIP files 
is expected to not include a byte order mark (BOM). 

D.3 Applications MAY choose to supplement this file name storage through the use 
of the 0x0008 Extra Field.  Storage for this optional field is currently 
undefined, however it will be used to allow storing extended information 
on source or target encoding that MAY further assist applications with file 
name, or file content encoding tasks.  Please contact PKWARE with any
requirements on how this field SHOULD be used.

D.4 The 0x0008 Extra Field storage MAY be used with either setting for general 
purpose bit 11.  Examples of the intended usage for this field is to store 
whether "modified-UTF-8" (JAVA) is used, or UTF-8-MAC.  Similarly, other 
commonly used character encoding (code page) designations can be indicated 
through this field.  Formalized values for use of the 0x0008 record remain 
undefined at this time.  The definition for the layout of the 0x0008 field
will be published when available.  Use of the 0x0008 Extra Field provides
for storing data within a ZIP file in an encoding other than IBM Code
Page 437 or UTF-8.

D.5 General purpose bit 11 will not imply any encoding of file content or
password.  Values defining character encoding for file content or 
password MUST be stored within the 0x0008 Extended Language Encoding 
Extra Field.

D.6 Ed Gordon of the Info-ZIP group has defined a pair of "extra field" records 
that can be used to store UTF-8 file name and file comment fields.  These
records can be used for cases when the general purpose bit 11 method
for storing UTF-8 data in the standard file name and comment fields is
not desirable.  A common case for this alternate method is if backward
compatibility with older programs is required.

D.7 Definitions for the record structure of these fields are included above 
in the section on 3rd party mappings for "extra field" records.  These
records are identified by Header ID's 0x6375 (Info-ZIP Unicode Comment 
Extra Field) and 0x7075 (Info-ZIP Unicode Path Extra Field).

D.8 The choice of which storage method to use when writing a ZIP file is left
to the implementation.  Developers SHOULD expect that a ZIP file MAY 
contain either method and SHOULD provide support for reading data in 
either format. Use of general purpose bit 11 reduces storage requirements 
for file name data by not requiring additional "extra field" data for
each file, but can result in older ZIP programs not being able to extract 
files.  Use of the 0x6375 and 0x7075 records will result in a ZIP file 
that SHOULD always be readable by older ZIP programs, but requires more 
storage per file to write file name and/or file comment fields.


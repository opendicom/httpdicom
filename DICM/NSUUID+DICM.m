#import "NSUUID+DICM.h"

@implementation NSUUID (DICM)

union UUIDbytes
{
    uuid_t bytesPointer;
    uint64 uint64Pointer[2];
};

/*
 128 bit values are represented by a max of 38 digits in decimal notation
    [39]    values
    [4]     1x,2x,4x,8x
    [2]     MSW, LSW
 
 18446744073709551616
 */
static uint64 digitParts[4] = { 1,2,4,8 };
static uint64 substractor[39][4][2] = {
        {{0x0000000000000000,0x0000000000000001}, {0x0000000000000000,0x0000000000000002}, {0x0000000000000000,0x0000000000000004}, {0x0000000000000000,0x0000000000000008}},
        {{0x0000000000000000,0x000000000000000A}, {0x0000000000000000,0x0000000000000014}, {0x0000000000000000,0x0000000000000028}, {0x0000000000000000,0x0000000000000050}},
        {{0x0000000000000000,0x0000000000000064}, {0x0000000000000000,0x00000000000000C8}, {0x0000000000000000,0x0000000000000190}, {0x0000000000000000,0x0000000000000320}},
        {{0x0000000000000000,0x00000000000003E8}, {0x0000000000000000,0x00000000000007D0}, {0x0000000000000000,0x0000000000000FA0}, {0x0000000000000000,0x0000000000001F40}},
        {{0x0000000000000000,0x0000000000002710}, {0x0000000000000000,0x0000000000004E20}, {0x0000000000000000,0x0000000000009C40}, {0x0000000000000000,0x0000000000013880}},
        {{0x0000000000000000,0x00000000000186A0}, {0x0000000000000000,0x0000000000030D40}, {0x0000000000000000,0x0000000000061A80}, {0x0000000000000000,0x00000000000C3500}},
        {{0x0000000000000000,0x00000000000F4240}, {0x0000000000000000,0x00000000001E8480}, {0x0000000000000000,0x00000000003D0900}, {0x0000000000000000,0x00000000007A1200}},
        {{0x0000000000000000,0x0000000000989680}, {0x0000000000000000,0x0000000001312D00}, {0x0000000000000000,0x0000000002625A00}, {0x0000000000000000,0x0000000004C4B400}},
        {{0x0000000000000000,0x0000000005F5E100}, {0x0000000000000000,0x000000000BEBC200}, {0x0000000000000000,0x0000000017D78400}, {0x0000000000000000,0x000000002FAF0800}},
        {{0x0000000000000000,0x000000003B9ACA00}, {0x0000000000000000,0x0000000077359400}, {0x0000000000000000,0x00000000EE6B2800}, {0x0000000000000000,0x00000001DCD65000}},
    
        {{0x0000000000000000,0x00000002540BE400}, {0x0000000000000000,0x00000004A817C800}, {0x0000000000000000,0x00000009502F9000}, {0x0000000000000000,0x00000012A05F2000}},
        {{0x0000000000000000,0x000000174876E800}, {0x0000000000000000,0x0000002E90EDD000}, {0x0000000000000000,0x0000005D21DBA000}, {0x0000000000000000,0x000000BA43B74000}},
        {{0x0000000000000000,0x000000E8D4A51000}, {0x0000000000000000,0x000001D1A94A2000}, {0x0000000000000000,0x000003A352944000}, {0x0000000000000000,0x00000746A5288000}},
        {{0x0000000000000000,0x000009184E72A000}, {0x0000000000000000,0x000012309CE54000}, {0x0000000000000000,0x0000246139CA8000}, {0x0000000000000000,0x000048C273950000}},
        {{0x0000000000000000,0x00005AF3107A4000}, {0x0000000000000000,0x0000B5E620F48000}, {0x0000000000000000,0x00016BCC41E90000}, {0x0000000000000000,0x0002D79883D20000}},
        {{0x0000000000000000,0x00038D7EA4C68000}, {0x0000000000000000,0x00071AFD498D0000}, {0x0000000000000000,0x000E35FA931A0000}, {0x0000000000000000,0x001C6BF526340000}},
        {{0x0000000000000000,0x002386F26FC10000}, {0x0000000000000000,0x00470DE4DF820000}, {0x0000000000000000,0x008E1BC9BF040000}, {0x0000000000000000,0x011C37937E080000}},
        {{0x0000000000000000,0x016345785D8A0000}, {0x0000000000000000,0x02C68AF0BB140000}, {0x0000000000000000,0x058D15E176280000}, {0x0000000000000000,0x0B1A2BC2EC500000}},
        {{0x0000000000000000,0x0DE0B6B3A7640000}, {0x0000000000000000,0x1BC16D674EC80000}, {0x0000000000000000,0x3782DACE9D900000}, {0x0000000000000000,0x6F05B59D3B200000}},
        {{0x0000000000000000,0x8AC7230489E80000}, {0x0000000000000001,0x158E460913D00000}, {0x0000000000000002,0x2B1C8C1227A00000}, {0x0000000000000004,0x563918244F400000}},
    
        {{0x0000000000000005,0x6BC75E2D63100000}, {0x000000000000000A,0xD78EBC5AC6200000}, {0x0000000000000015,0xAF1D78B58C400000}, {0x000000000000002B,0x5E3AF16B18800000}},
        {{0x0000000000000036,0x35C9ADC5DEA00000}, {0x000000000000006C,0x6B935B8BBD400000}, {0x00000000000000D8,0xD726B7177A800000}, {0x00000000000001B1,0xAE4D6E2EF5000000}},
        {{0x000000000000021E,0x19E0C9BAB2400000}, {0x000000000000043C,0x33C1937564800000}, {0x0000000000000878,0x678326EAC9000000}, {0x00000000000010F0,0xCF064DD592000000}},
        {{0x000000000000152D,0x02C7E14AF6800000}, {0x0000000000002A5A,0x058FC295ED000000}, {0x00000000000054B4,0x0B1F852BDA000000}, {0x000000000000A968,0x163F0A57B4000000}},
        {{0x000000000000D3C2,0x1BCECCEDA1000000}, {0x000000000001A784,0x379D99DB42000000}, {0x0000000000034F08,0x6F3B33B684000000}, {0x0000000000069E10,0xDE76676D08000000}},
        {{0x0000000000084595,0x161401484A000000}, {0x0000000000108B2A,0x2C28029094000000}, {0x0000000000211654,0x5850052128000000}, {0x0000000000422CA8,0xB0A00A4250000000}},
        {{0x000000000052B7D2,0xDCC80CD2E4000000}, {0x0000000000A56FA5,0xB99019A5C8000000}, {0x00000000014ADF4B,0x7320334B90000000}, {0x000000000295BE96,0xE640669720000000}},
        {{0x00000000033B2E3C,0x9FD0803CE8000000}, {0x0000000006765C79,0x3FA10079D0000000}, {0x000000000CECB8F2,0x7F4200F3A0000000}, {0x0000000019D971E4,0xFE8401E740000000}},
        {{0x00000000204FCE5E,0x3E25026110000000}, {0x00000000409F9CBC,0x7C4A04C220000000}, {0x00000000813F3978,0xF894098440000000}, {0x00000001027E72F1,0xF128130880000000}},
        {{0x00000001431E0FAE,0x6D7217CAA0000000}, {0x00000002863C1F5C,0xDAE42F9540000000}, {0x000000050C783EB9,0xB5C85F2A80000000}, {0x0000000A18F07D73,0x6B90BE5500000000}},
    
        {{0x0000000C9F2C9CD0,0x4674EDEA40000000}, {0x000000193E5939A0,0x8CE9DBD480000000}, {0x000000327CB27341,0x19D3B7A900000000}, {0x00000064F964E682,0x33A76F5200000000}},
        {{0x0000007E37BE2022,0xC0914B2680000000}, {0x000000FC6F7C4045,0x8122964D00000000}, {0x000001F8DEF8808B,0x02452C9A00000000}, {0x000003F1BDF10116,0x048A593400000000}},
        {{0x000004EE2D6D415B,0x85ACEF8100000000}, {0x000009DC5ADA82B7,0x0B59DF0200000000}, {0x000013B8B5B5056E,0x16B3BE0400000000}, {0x000027716B6A0ADC,0x2D677C0800000000}},
        {{0x0000314DC6448D93,0x38C15B0A00000000}, {0x0000629B8C891B26,0x7182B61400000000}, {0x0000C5371912364C,0xE3056C2800000000}, {0x00018A6E32246C99,0xC60AD85000000000}},
        {{0x0001ED09BEAD87C0,0x378D8E6400000000}, {0x0003DA137D5B0F80,0x6F1B1CC800000000}, {0x0007B426FAB61F00,0xDE36399000000000}, {0x000F684DF56C3E01,0xBC6C732000000000}},
        {{0x0013426172C74D82,0x2B878FE800000000}, {0x002684C2E58E9B04,0x570F1FD000000000}, {0x004D0985CB1D3608,0xAE1E3FA000000000}, {0x009A130B963A6C11,0x5C3C7F4000000000}},
        {{0x00C097CE7BC90715,0xB34B9F1000000000}, {0x01812F9CF7920E2B,0x66973E2000000000}, {0x03025F39EF241C56,0xCD2E7C4000000000}, {0x0604BE73DE4838AD,0x9A5CF88000000000}},
        {{0x0785EE10D5DA46D9,0x00F436A000000000}, {0x0F0BDC21ABB48DB2,0x01E86D4000000000}, {0x1E17B84357691B64,0x03D0DA8000000000}, {0x3C2F7086AED236C8,0x07A1B50000000000}},
        {{0x4B3B4CA85A86C47A,0x098A224000000000}, {0x96769950B50D88F4,0x1314448000000000}, {0xFFFFFFFFFFFFFFFF,0xFFFFFFFFFFFFFFFF}, {0xFFFFFFFFFFFFFFFF,0xFFFFFFFFFFFFFFFF}}
};

-(NSString*)ITUTX667UIDString
{
    //http://www.itu.int/ITU-T/studygroups/com17/oid/X.667-E.pdf
    //2.25.uuidRepresentadoDecimal

    union UUIDbytes uuid;
    [self getUUIDBytes:uuid.bytesPointer];    
    return [@"2.25."stringByAppendingString:[self base10StringOfUInt64MSW:CFSwapInt64BigToHost(uuid.uint64Pointer[0]) LSW:CFSwapInt64BigToHost(uuid.uint64Pointer[1])]];
}


-(NSString*)base10StringOfUInt64MSW:(uint64)MSW LSW:(uint64)LSW
{    
    register uint64 m = MSW;
    register uint64 n = 0;
    register uint64 l = LSW;
    register uint64 o = 0;
    register uint64 max = 0xFFFFFFFFFFFFFFFF;
    
    NSMutableString *base10String = [NSMutableString string];

    for (int i=38;i>=0;i--)
    {
        unsigned char digit=0;
        for (int j=3;j>=0;j--)
        {            
            n=substractor[i][j][0];
            o=substractor[i][j][1];
            
            //NSLog(@"%08qX%08qX - %08qX%08qX",m,l,n,o);

            if ((m>n)||((m==n)&&(l>=o)))
            {
                digit+=digitParts[j];
                if (l<o)
                {
                    l= max-o+l-1;
                    m--;
                }
                else l-=o;
                m-=n;
            }
        }
        //NSLog(@"%@",[NSString stringWithFormat:@"%u",digit]);

        [base10String insertString:[NSString stringWithFormat:@"%u",digit] atIndex:0];
    }
    

    while ([base10String characterAtIndex:0]=='0')
    {
        [base10String deleteCharactersInRange:NSMakeRange(0,1)];
    }

    return [NSString stringWithString:base10String];
}

@end

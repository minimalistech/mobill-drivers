//
//  LzssAlgorithm.m
//  CoolLED1248
//
//  Created by 君同 on 2023/3/8.
//  Copyright © 2023 Haley. All rights reserved.
//

#import "LzssAlgorithm.h"

#define N 512 // 缓冲区长度即字典区，一定要为2的次方，一般定义为4096，越长压缩比越高，但是由于设备RAM空间有限，大小为512;
#define F 18 // 最大的输出长度
static int THRESHOLD = 2; // 最小的数据长度要大于THRESHOLD，即=THRESHOLD+1
static int NIL = N;

@interface LzssAlgorithm ()
{
    int lson[N + 1];
    int rson[N + 257];
    int dad[N + 1];
    Byte *enbuffer[N + F - 1];
}
@property (nonatomic, assign) int textsize;
@property (nonatomic, assign) int codesize;
@property (nonatomic, assign) int printcount;

@property (nonatomic, assign) int match_position;
@property (nonatomic, assign) int match_length;
@end
@implementation LzssAlgorithm

- (instancetype)init
{
    if (self = [super init]) {
    
        _textsize = 0;
        _codesize = 0;
        _printcount = 0;
        
        _match_position = 0;
        _match_length = 0;
    }
    return self;
}

-(void)InitTree{
    int  i = 0;

    for (i = N + 1; i <= N + 256; i++)
    {
        rson[i] = NIL;
    }

    for (i = 0; i < N; i++)
    {
        dad[i] = NIL;
    }
}


//插入一个节点
//@param {Number} r

-(void)InsertNode:(int) r {
    int i=0, p=0, cmp=0;
    
    cmp = 1;
    p = N + 1 + (int)(enbuffer[r]); // 这里需要按照无符号的方式去做加减计算
    
    rson[r] = lson[r] = NIL;
    self.match_length = 0;

    for (; ; )
    {
        if (cmp >= 0)
        {
            if (rson[p] != NIL)
            {
                p = rson[p];
            }
            else
            {
                rson[p] = r;
                dad[r] = p;
                return;
            }
        }
        else
        {
            if (lson[p] != NIL)
            {
                p = lson[p];
            }
            else
            {
                lson[p] = r;
                dad[r] = p;
                return;
            }
        }

        for (i = 1; i < F; i++)
        {
            cmp = (int)(enbuffer[r+i]) - (int)(enbuffer[p + i]);
            if (cmp != 0)
            {
                break;
            }
        }
        
        if (i > self.match_length)
        {
            self.match_position = p;
            
            self.match_length = i;
            if (self.match_length >= F)
            {
                break;
            }
        }
    }

    dad[r] = dad[p];
    lson[r] = lson[p];
    rson[r] = rson[p];
    dad[lson[p]] = r;
    dad[rson[p]] = r;

    if (rson[dad[p]] == p)
    {
        rson[dad[p]] = r;
    }
    else
    {
        lson[dad[p]] = r;
    }

    dad[p] = NIL;
}

//删除一个节点
//@param {Number} p

-(void)DeleteNode:(int) p {
    int q = 0;

    if (dad[p] == NIL)
    {
        return;
    }

    if (rson[p] == NIL)
    {
        q = lson[p];
    }
    else if (lson[p] == NIL)
    {
        q = rson[p];
    }
    else
    {
        q = lson[p];

        if (rson[q] != NIL)
        {
            do
            {
                q = rson[q];
            }
            while (rson[q] != NIL);

            rson[dad[q]] = lson[q];
            dad[lson[q]] = dad[q];
            lson[q] = lson[p];
            dad[lson[p]] = q;
        }

        rson[q] = rson[p];
        dad[rson[p]] = q;
    }

    dad[q] = dad[p];

    if (rson[dad[p]] == p)
    {
        rson[dad[p]] = q;
    }
    else
    {
        lson[dad[p]] = q;
    }

    dad[p] = NIL;
}

//压缩一段数据
//@param {byte[]} data
//返回: 压缩后的数据
- (NSData *)lzssEncode:(NSData *)dataDa {
    Byte *data = (Byte *)[dataDa bytes];
    
    int i, len, r, s, last_match_length, code_buf_ptr;
    Byte c = 0, mask = 0;
    Byte code_buf[17];
    int currEncodeIndex = 0; // 当前处理的数据位置
    int encodeDataLen = (int)dataDa.length; // 压缩数据的原始长度
    NSMutableData *resultBufferData = [NSMutableData data]; // 使用NSMutableData存储压缩结果

    self.textsize = 0;
    self.codesize = 0;
    self.printcount = 0;

    [self InitTree];

    code_buf[0] = 0;
    code_buf_ptr = mask = 1;
    s = 0;
    r = N - F;

    for (i = s; i < r; i++) {
        enbuffer[i] = 0;
    }

    for (len = 0; len < F && currEncodeIndex < encodeDataLen; len++, currEncodeIndex++) {
        enbuffer[r + len] = data[currEncodeIndex];
    }
    
    self.textsize = len;
    if (self.textsize == 0) {
        return nil;
    }

    for (i = 1; i <= F; i++) {
        [self InsertNode:(r - i)];
    }

    [self InsertNode:(r)];

    do {
        if (self.match_length > len) {
            self.match_length = len;
        }

        if (self.match_length <= THRESHOLD) {
            self.match_length = 1;
            code_buf[0] |= mask;
            code_buf[code_buf_ptr++] = enbuffer[r];
        } else {
            code_buf[code_buf_ptr++] = (Byte)(self.match_position & 0xFF);
            code_buf[code_buf_ptr++] = (Byte)(((self.match_position >> 4) & 0xf0) | (self.match_length - (THRESHOLD + 1))); // >>为不带符号的右移
        }

        // 状态标志flag只有一个字节，8bit
        mask <<= 1;
        if ((mask & 0xFF) == 0) {
            // 将 code_buf 添加到 resultBufferData
            if (code_buf_ptr > 1) {
                [resultBufferData appendBytes:code_buf length:code_buf_ptr];
                self.codesize += code_buf_ptr;
                code_buf[0] = 0;
                code_buf_ptr = mask = 1;
            }
        }

        last_match_length = self.match_length;

        for (i = 0; i < last_match_length && currEncodeIndex < encodeDataLen; i++, currEncodeIndex++) {
            [self DeleteNode:s];

            c = data[currEncodeIndex];

            enbuffer[s] = c;

            if (s < F - 1) {
                enbuffer[s + N] = c;
            }

            s = (s + 1) & (N - 1);
            r = (r + 1) & (N - 1);
            [self InsertNode:r];
        }

        self.textsize += i;
        if (self.textsize > self.printcount) {
            self.printcount += 1024;
        }

        while (i++ < last_match_length) {
            [self DeleteNode:s];
            s = (s + 1) & (N - 1);
            r = (r + 1) & (N - 1);
            if (--len > 0) {
                [self InsertNode:r];
            }
        }
    } while (len > 0);

    // 处理剩余的 code_buf
    if (code_buf_ptr > 1) {
        [resultBufferData appendBytes:code_buf length:code_buf_ptr];
        self.codesize += code_buf_ptr;
    }
    
//    NSLog(@"In : %d", self.textsize);
//    NSLog(@"Out: %d", self.codesize);
//    NSLog(@"Out/In:  %f", (double)self.codesize / self.textsize); // 压缩比
    
    return [resultBufferData copy]; // 返回压缩后的数据
}

@end

package com.mobilldriversprotocol;

import java.util.ArrayList;
import java.util.List;

/**
 * LZSS Compression Algorithm
 * Extracted from CoolLED1248 Android app
 * Copyright © JTKJ LED1248. All rights reserved.
 */
public class LzssAlgorithm {
    
    private static final int N = 512; // 缓冲区长度即字典区，一定要为2的次方，一般定义为4096，越长压缩比越高，但是由于设备RAM空间有限，大小为512
    private static final int F = 18; // 最大的输出长度
    private static final int THRESHOLD = 2; // 最小的数据长度要大于THRESHOLD，即=THRESHOLD+1
    private static final int NIL = N;
    
    private static int textsize = 0;
    private static int codesize = 0;
    private static int printcount = 0;
    private static byte[] enbuffer = new byte[N + F - 1]; // 压缩解压所要用到的缓冲区
    private static int match_position = 0;
    private static int match_length = 0;
    private static int[] lson = new int[N + 1];
    private static int[] rson = new int[N + 257];
    private static int[] dad = new int[N + 1];
    
    /**
     * 初始化二叉树 lson为左叶子节点，rson为右子节点，dad为父节点
     * FIXED: Also initialize lson array to prevent corruption from previous calls
     */
    public static void InitTree() {
        int i;

        // Initialize all arrays to NIL to prevent corruption from previous calls
        // This is critical for thread-safety and preventing ArrayIndexOutOfBoundsException
        for (i = 0; i < N + 1; i++) {
            lson[i] = NIL;
            dad[i] = NIL;
        }

        for (i = 0; i < N + 257; i++) {
            rson[i] = NIL;
        }

        // Reset state variables
        match_position = 0;
        match_length = 0;

        // Clear enbuffer
        for (i = 0; i < N + F - 1; i++) {
            enbuffer[i] = 0;
        }
    }
    
    /**
     * 插入一个节点
     *
     * @param r node index
     */
    public static void InsertNode(int r) {
        int i = 0, p = 0, cmp = 0;
        cmp = 1;
        p = N + 1 + Byte.toUnsignedInt(enbuffer[r]); // 这里需要按照无符号的方式去做加减计算
        rson[r] = lson[r] = NIL;
        match_length = 0;
        
        for (; ; ) {
            if (cmp >= 0) {
                if (rson[p] != NIL) {
                    p = rson[p];
                } else {
                    rson[p] = r;
                    dad[r] = p;
                    return;
                }
            } else {
                if (lson[p] != NIL) {
                    p = lson[p];
                } else {
                    lson[p] = r;
                    dad[r] = p;
                    return;
                }
            }
            
            for (i = 1; i < F; i++) {
                cmp = Byte.toUnsignedInt(enbuffer[r + i]) - Byte.toUnsignedInt(enbuffer[p + i]);
                if (cmp != 0) {
                    break;
                }
            }
            
            if (i > match_length) {
                match_position = p;
                match_length = i;
                if (match_length >= F) {
                    break;
                }
            }
        }
        
        dad[r] = dad[p];
        lson[r] = lson[p];
        rson[r] = rson[p];
        dad[lson[p]] = r;
        dad[rson[p]] = r;
        
        if (rson[dad[p]] == p) {
            rson[dad[p]] = r;
        } else {
            lson[dad[p]] = r;
        }
        
        dad[p] = NIL;
    }
    
    /**
     * 删除一个节点
     *
     * @param p node index to delete
     */
    public static void DeleteNode(int p) {
        int q = 0;
        
        if (dad[p] == NIL) {
            return;
        }
        
        if (rson[p] == NIL) {
            q = lson[p];
        } else if (lson[p] == NIL) {
            q = rson[p];
        } else {
            q = lson[p];
            
            if (rson[q] != NIL) {
                do {
                    q = rson[q];
                } while (rson[q] != NIL);
                
                rson[dad[q]] = lson[q];
                dad[lson[q]] = dad[q];
                lson[q] = lson[p];
                dad[lson[p]] = q;
            }
            
            rson[q] = rson[p];
            dad[rson[p]] = q;
        }
        
        dad[q] = dad[p];
        
        if (rson[dad[p]] == p) {
            rson[dad[p]] = q;
        } else {
            lson[dad[p]] = q;
        }
        
        dad[p] = NIL;
    }
    
    /**
     * LZSS压缩核心算法
     * Ported from manufacturer's CoolledUUtils.java
     * @param data 输入字节数组
     * @return 压缩后的字节数组
     *
     * FIXED: synchronized to prevent concurrent access to static arrays
     */
    public static synchronized byte[] lzssCompress(byte[] data) {
        if (data == null || data.length == 0) {
            return data;
        }

        int i, len, r, s, last_match_length, code_buf_ptr;
        byte c = 0, mask = 0;
        byte[] code_buf = new byte[17];
        int currEncodeIndex = 0; // 当前处理的数据位置
        int encodeDataLen = data.length; // 压缩数据的原始长度
        List<Byte> resultBuffer = new ArrayList<Byte>(); // 压缩结果输出

        textsize = 0;
        codesize = 0;
        printcount = 0;

        InitTree();

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

        textsize = len;
        if (textsize == 0) {
            return null;
        }

        for (i = 1; i <= F; i++) {
            InsertNode(r - i);
        }

        InsertNode(r);

        do {
            if (match_length > len) {
                match_length = len;
            }

            if (match_length <= THRESHOLD) {
                match_length = 1;
                code_buf[0] |= mask;
                code_buf[code_buf_ptr++] = enbuffer[r];
            } else {
                code_buf[code_buf_ptr++] = (byte) (match_position & 0xFF);
                code_buf[code_buf_ptr++] = (byte) (((match_position >>> 4) & 0xf0) | (match_length - (THRESHOLD + 1))); // >>>为不带符号的右移
            }

            // 状态标志flag只有一个字节，8bit
            mask <<= 1;
            if ((mask & 0xFF) == 0) {
                for (i = 0; i < code_buf_ptr; i++) {
                    resultBuffer.add(code_buf[i]);
                }

                codesize += code_buf_ptr;
                code_buf[0] = 0;
                code_buf_ptr = mask = 1;
            }

            last_match_length = match_length;

            for (i = 0; i < last_match_length && currEncodeIndex < encodeDataLen; i++, currEncodeIndex++) {
                DeleteNode(s);

                c = data[currEncodeIndex];

                enbuffer[s] = c;

                if (s < F - 1) {
                    enbuffer[s + N] = c;
                }

                s = (s + 1) & (N - 1);
                r = (r + 1) & (N - 1);
                InsertNode(r);
            }

            textsize += i;
            if (textsize > printcount) {
                printcount += 1024;
            }

            while (i++ < last_match_length) {
                DeleteNode(s);
                s = (s + 1) & (N - 1);
                r = (r + 1) & (N - 1);
                if (--len > 0) {
                    InsertNode(r);
                }
            }
        } while (len > 0);

        if (code_buf_ptr > 1) {
            for (i = 0; i < code_buf_ptr; i++) {
                resultBuffer.add(code_buf[i]);
            }
            codesize += code_buf_ptr;
        }

        byte[] result = new byte[resultBuffer.size()];
        for (i = 0; i < resultBuffer.size(); i++) {
            result[i] = (byte) resultBuffer.get(i).intValue();
        }

        return result;
    }
    
    /**
     * 获取LZSS压缩数据
     * @param input 输入字符串列表
     * @return 压缩后的字符串列表
     */
    public static List<String> getLzssCompressData(List<String> input) {
        byte[] inputByteData = fromListStringToByteArray(input);
        byte[] resultByteData = lzssCompress(inputByteData);
        List<String> result = new ArrayList<>();
        result.addAll(byteArrayToHexList(resultByteData));

        // Log compression stats
        double ratio = (inputByteData.length > 0) ? (double) resultByteData.length / inputByteData.length * 100 : 0;
        android.util.Log.d("LzssAlgorithm", "[LZSS] Input: " + inputByteData.length + " bytes, Output: " + resultByteData.length + " bytes, Ratio: " + String.format("%.1f%%", ratio));

        return result;
    }
    
    // 辅助方法 - 将字符串列表转换为字节数组
    private static byte[] fromListStringToByteArray(List<String> input) {
        byte[] result = new byte[input.size()];
        for (int i = 0; i < input.size(); i++) {
            result[i] = (byte) Integer.parseInt(input.get(i), 16);
        }
        return result;
    }
    
    // 辅助方法 - 将字节数组转换为十六进制字符串列表
    private static List<String> byteArrayToHexList(byte[] bytes) {
        List<String> result = new ArrayList<>();
        for (byte b : bytes) {
            result.add(String.format("%02X", b & 0xFF).toLowerCase());
        }
        return result;
    }
}
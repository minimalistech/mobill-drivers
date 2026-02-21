package com.mobilldriversprotocol;

import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Typeface;
import android.util.Log;

import com.mobilldriversprotocol.models.*;
import com.mobilldriversprotocol.Crc32Algorithm;
import com.mobilldriversprotocol.LzssAlgorithm;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * CoolledUProtocol - Protocol wrapper for CoolLEDU devices
 * Implements the manufacturer's two-phase transmission protocol
 *
 * Protocol Flow:
 * 1. Client sends beginDataForProgram (handshake with metadata)
 * 2. Device responds with notification (status)
 * 3. Client sends dataForProgram packets sequentially
 * 4. Device responds after each packet with index and status
 * 5. Repeat until all packets sent
 *
 * Copyright © 2024 Mobill. All rights reserved.
 */
public class CoolledUProtocol {

    private static final String TAG = "CoolledUProtocol";

    // BLE UUIDs for CoolLEDU devices
    public static final String UUID_SERVICE = "0000fff0-0000-1000-8000-00805f9b34fb";
    public static final String UUID_CHARACTER = "0000fff1-0000-1000-8000-00805f9b34fb";

    // Protocol response codes
    public static final int RESPONSE_SUCCESS = 0x00;
    public static final int RESPONSE_TRANSMISSION_FAILED = 0x01;
    public static final int RESPONSE_DEVICE_ERROR = 0x02;
    public static final int RESPONSE_DATA_ERROR = 0x03;

    /**
     * DataResult - Contains begin packet and data packets for a program
     */
    public static class DataResult {
        public List<String> beginDataForProgram;      // Initial handshake packet
        public List<List<String>> dataForProgram;     // Array of data packets
    }

    /**
     * TextRenderResult - Holds per-character text rendering results
     * Shared between getDataWithTextContent and getDataWithCustomColorContent
     */
    static class TextRenderResult {
        String sumCheckedString;  // Concatenated per-character bitmap hex data
        int wordsLength;          // Total width in columns
        String wordsWidth;        // Per-char widths (1 byte each, hex)
        String wordsColor;        // Per-char colors (2 bytes each, hex)
    }

    // Cache for text rendering results (single-threaded protocol generation)
    private static TextRenderResult lastTextRenderResult;

    /**
     * Generate complete DataResult for a ColorItemModel32 program
     *
     * @param colorItemModel The program to transmit
     * @param programIndex Program index in transmission sequence (0-8)
     * @param programCount Total programs being sent (1-9)
     * @return DataResult with begin and data packets
     */
    public static DataResult getDataResult(ColorItemModel32 colorItemModel, int programIndex, int programCount) {
        DataResult dataResult = new DataResult();

        Log.d(TAG, "[PROTOCOL] ===== GENERATING PROTOCOL DATA =====");
        Log.d(TAG, "[PROTOCOL] programIndex: " + programIndex + ", programCount: " + programCount);

        // 1. Generate program data (this is the UNCOMPRESSED data used for CRC and length in begin packet)
        List<String> originalProgramData = getDataWithProgram(colorItemModel);
        Log.d(TAG, "[PROTOCOL] 1. Original program data size: " + originalProgramData.size() + " bytes");

        // 2. Create begin packet (handshake) - uses UNCOMPRESSED data for CRC and length
        dataResult.beginDataForProgram = getStartDataForProgram(originalProgramData, programIndex, programCount);
        Log.d(TAG, "[PROTOCOL] 2. Begin packet created, size: " + dataResult.beginDataForProgram.size() + " bytes");

        // 3. Compress data using LZSS
        List<String> compressedData = LzssAlgorithm.getLzssCompressData(originalProgramData);
        Log.d(TAG, "[PROTOCOL] 3. Compressed data size: " + compressedData.size() + " bytes");

        // 4. Split into packets - uses COMPRESSED data
        dataResult.dataForProgram = getDataPacket(compressedData, "03");
        Log.d(TAG, "[PROTOCOL] 4. Data packets created: " + dataResult.dataForProgram.size() + " packets");

        Log.d(TAG, "[PROTOCOL] ===== END PROTOCOL DATA GENERATION =====");

        return dataResult;
    }

    /**
     * Generate program data from ColorItemModel32
     * Format: [reserved 8 bytes][content count][show count][content data...]
     */
    private static List<String> getDataWithProgram(ColorItemModel32 colorItemModel) {
        List<String> result = new ArrayList<>();

        Log.d(TAG, "[DATA_GEN] ===== START ITEM CONTENT GENERATION =====");
        Log.d(TAG, "[DATA_GEN] masterplateCaseType: " + colorItemModel.getMasterplateCaseType());
        Log.d(TAG, "[DATA_GEN] itemContentCount: " + colorItemModel.getItemContentCount());
        Log.d(TAG, "[DATA_GEN] itemShowTime: " + colorItemModel.getItemShowTime());
        Log.d(TAG, "[DATA_GEN] deviceIdentify: " + colorItemModel.getItemDeviceIdentify());

        // Reserved bytes
        for (int i = 0; i < 8; i++) {
            result.add("00");
        }
        Log.d(TAG, "[DATA_GEN] Added 8 reserved bytes, current length: " + result.size());

        // Content count (how many content items in this program)
        result.addAll(getHexListStringForWithOneByte(colorItemModel.getItemContentCount()));
        Log.d(TAG, "[DATA_GEN] Added itemContentCount (" + colorItemModel.getItemContentCount() + "), current length: " + result.size());

        // Show count (how many times to display this program)
        result.addAll(getHexListStringForWithOneByte(colorItemModel.getItemShowTime()));
        Log.d(TAG, "[DATA_GEN] Added itemShowTime (" + colorItemModel.getItemShowTime() + "), current length: " + result.size());

        // Content data (graffiti, animation, text)
        List<String> contentData = getDataForCombineProgram(colorItemModel);
        result.addAll(contentData);
        Log.d(TAG, "[DATA_GEN] Added content data, total length: " + result.size());

        // Show first 100 chars of hex
        StringBuilder hex = new StringBuilder();
        for (int i = 0; i < Math.min(50, result.size()); i++) {
            hex.append(result.get(i));
        }
        Log.d(TAG, "[DATA_GEN] First 100 chars: " + hex.toString());
        Log.d(TAG, "[DATA_GEN] ===== END ITEM CONTENT GENERATION =====");

        return result;
    }

    /**
     * Generate content data from ColorItemModel32
     * Routes to graffiti, animation, or text generator based on content type
     */
    private static List<String> getDataForCombineProgram(ColorItemModel32 colorItemModel) {
        List<String> result = new ArrayList<>();

        // Graffiti (images)
        if (colorItemModel.getGraffitiModel32Arr() != null && !colorItemModel.getGraffitiModel32Arr().isEmpty()) {
            for (GraffitiModel32 graffiti : colorItemModel.getGraffitiModel32Arr()) {
                result.addAll(getDataWithGraffitiContent(graffiti));
            }
        }

        // Animations
        if (colorItemModel.getAnimationModel32Arr() != null && !colorItemModel.getAnimationModel32Arr().isEmpty()) {
            for (AnimationModel32 animation : colorItemModel.getAnimationModel32Arr()) {
                result.addAll(getDataWithAnimationContent(animation));
            }
        }

        // Text
        if (colorItemModel.getColorTextModel32Arr() != null && !colorItemModel.getColorTextModel32Arr().isEmpty()) {
            for (ColorTextModel32 text : colorItemModel.getColorTextModel32Arr()) {
                // CRITICAL: Render text FIRST to populate lastTextRenderResult cache,
                // then build custom color block using those render results.
                // Output order: type 06 (custom color) BEFORE type 01 (text bitmap)
                // See iOS JTTool.m lines 2284-2305
                List<String> textData = getDataWithTextContent(text);

                if (text.getColorShowType() == 1) {
                    result.addAll(getDataWithCustomColorContent(text));
                }
                result.addAll(textData);
            }
        }

        return result;
    }

    /**
     * Generate graffiti/image content data
     */
    private static List<String> getDataWithGraffitiContent(GraffitiModel32 graffiti) {
        // Build content data first (without total length prefix)
        List<String> contentData = new ArrayList<>();

        // Content type identifier - FIXED: Use "02" for graffiti (was "01")
        contentData.add("02");

        // 7 reserved bytes (matching iOS implementation)
        for (int i = 0; i < 7; i++) {
            contentData.add("00");
        }

        // Position and size - LOG VALUES FOR DEBUGGING
        Log.d(TAG, "[GRAFFITI_DATA] coverTypeGraffiti: " + graffiti.getCoverTypeGraffiti());
        Log.d(TAG, "[GRAFFITI_DATA] startColGraffiti: " + graffiti.getStartColGraffiti());
        Log.d(TAG, "[GRAFFITI_DATA] startRowGraffiti: " + graffiti.getStartRowGraffiti());
        Log.d(TAG, "[GRAFFITI_DATA] widthDataGraffiti: " + graffiti.getWidthDataGraffiti());
        Log.d(TAG, "[GRAFFITI_DATA] heightDataGraffiti: " + graffiti.getHeightDataGraffiti());

        contentData.add(getHexStringForIntWithOneByte(graffiti.getCoverTypeGraffiti()));
        contentData.addAll(getHexListStringForIntWithTwo(graffiti.getStartColGraffiti()));
        contentData.addAll(getHexListStringForIntWithTwo(graffiti.getStartRowGraffiti()));
        contentData.addAll(getHexListStringForIntWithTwo(graffiti.getWidthDataGraffiti()));
        contentData.addAll(getHexListStringForIntWithTwo(graffiti.getHeightDataGraffiti()));

        // Display parameters
        contentData.add(getHexStringForIntWithOneByte(graffiti.getShowModelGraffiti()));
        // FIXED: Add +239 offset to speed (iOS: "+239解决速度变化非线性")
        contentData.add(getHexStringForIntWithOneByte(graffiti.getSpeedDataGraffiti() + 239));
        contentData.add(getHexStringForIntWithOneByte(graffiti.getStayTimeGraffiti()));

        // FIXED: Use compressed 4-bit color encoding (2 bytes per pixel, not 3)
        List<String> pixelData = convertPixelDataToHexListCompressed(graffiti.getDataGraffiti());

        // FIXED: Add 4-byte pixel data length field before pixel data
        contentData.addAll(getHexListStringForIntWithFour(pixelData.size()));
        contentData.addAll(pixelData);

        // FIXED: Prepend 4-byte total length (content size + 4 bytes for this length field)
        List<String> result = new ArrayList<>();
        result.addAll(getHexListStringForIntWithFour(contentData.size() + 4));
        result.addAll(contentData);

        // ENHANCED LOGGING: Show exact graffiti structure for debugging
        Log.d(TAG, "[GRAFFITI_BYTES] ===== GRAFFITI CONTENT STRUCTURE =====");
        Log.d(TAG, "[GRAFFITI_BYTES] Total size with 4-byte prefix: " + result.size() + " bytes");
        Log.d(TAG, "[GRAFFITI_BYTES] Content size (without prefix): " + contentData.size() + " bytes");
        Log.d(TAG, "[GRAFFITI_BYTES] Pixel data size: " + pixelData.size() + " bytes");

        // Show first 50 bytes in detail
        StringBuilder detailedHex = new StringBuilder();
        for (int i = 0; i < Math.min(50, result.size()); i++) {
            detailedHex.append(result.get(i)).append(" ");
            if ((i + 1) % 16 == 0) detailedHex.append("\n[GRAFFITI_BYTES]                    ");
        }
        Log.d(TAG, "[GRAFFITI_BYTES] First 50 bytes:\n[GRAFFITI_BYTES]                    " + detailedHex.toString());

        // Parse and show structure
        int pos = 0;
        Log.d(TAG, "[GRAFFITI_BYTES] Byte 0-3 (4-byte length): " + result.get(0) + " " + result.get(1) + " " + result.get(2) + " " + result.get(3) + " = " + (contentData.size() + 4) + " bytes");
        pos = 4;
        Log.d(TAG, "[GRAFFITI_BYTES] Byte 4 (type): " + result.get(pos) + " (should be 02 for graffiti)");
        pos++;
        Log.d(TAG, "[GRAFFITI_BYTES] Bytes 5-11 (7 reserved): " + result.get(5) + " " + result.get(6) + " " + result.get(7) + " " + result.get(8) + " " + result.get(9) + " " + result.get(10) + " " + result.get(11));
        pos = 12;
        Log.d(TAG, "[GRAFFITI_BYTES] Byte 12 (coverType): " + result.get(pos));
        Log.d(TAG, "[GRAFFITI_BYTES] Bytes 13-14 (startCol): " + result.get(13) + " " + result.get(14) + " = " + graffiti.getStartColGraffiti());
        Log.d(TAG, "[GRAFFITI_BYTES] Bytes 15-16 (startRow): " + result.get(15) + " " + result.get(16) + " = " + graffiti.getStartRowGraffiti());
        Log.d(TAG, "[GRAFFITI_BYTES] Bytes 17-18 (width): " + result.get(17) + " " + result.get(18) + " = " + graffiti.getWidthDataGraffiti());
        Log.d(TAG, "[GRAFFITI_BYTES] Bytes 19-20 (height): " + result.get(19) + " " + result.get(20) + " = " + graffiti.getHeightDataGraffiti());
        Log.d(TAG, "[GRAFFITI_BYTES] Byte 21 (showModel): " + result.get(21) + " = " + graffiti.getShowModelGraffiti());
        Log.d(TAG, "[GRAFFITI_BYTES] Byte 22 (speed+239): " + result.get(22) + " = " + (graffiti.getSpeedDataGraffiti() + 239));
        Log.d(TAG, "[GRAFFITI_BYTES] Byte 23 (stayTime): " + result.get(23) + " = " + graffiti.getStayTimeGraffiti());
        Log.d(TAG, "[GRAFFITI_BYTES] Bytes 24-27 (pixel length): " + result.get(24) + " " + result.get(25) + " " + result.get(26) + " " + result.get(27) + " = " + pixelData.size() + " bytes");
        Log.d(TAG, "[GRAFFITI_BYTES] Bytes 28+ (pixel data): " + result.get(28) + " " + result.get(29) + " " + result.get(30) + " " + result.get(31) + " " + result.get(32) + " " + result.get(33) + "...");
        Log.d(TAG, "[GRAFFITI_BYTES] ===== END GRAFFITI STRUCTURE =====");

        return result;
    }

    /**
     * Generate animation content data
     * Structure matches iOS JTTool.m getAnimationContent (lines 1339-1411)
     */
    private static List<String> getDataWithAnimationContent(AnimationModel32 animation) {
        // Build content data first (without total length prefix)
        List<String> contentData = new ArrayList<>();

        // 1. Content type identifier - "03" for animation (iOS line 1344)
        contentData.add("03");

        // 2. 7 reserved bytes (iOS lines 1347-1349)
        for (int i = 0; i < 7; i++) {
            contentData.add("00");
        }

        // 3. Cover type - 1 byte (iOS line 1352)
        contentData.add(getHexStringForIntWithOneByte(animation.getCoverTypeAnimation()));

        // 4. Start column - 2 bytes (iOS line 1355) - Note: iOS uses %04x for 2-byte values
        contentData.addAll(getHexListStringForIntWithTwo(animation.getStartColAnimation()));

        // 5. Start row - 2 bytes (iOS line 1358)
        contentData.addAll(getHexListStringForIntWithTwo(animation.getStartRowAnimation()));

        // 6. Width - 2 bytes (iOS line 1361)
        contentData.addAll(getHexListStringForIntWithTwo(animation.getWidthDataAnimation()));

        // 7. Height - 2 bytes (iOS line 1364)
        contentData.addAll(getHexListStringForIntWithTwo(animation.getHeightDataAnimation()));

        // 8. 1 reserved byte (iOS line 1367)
        contentData.add("00");

        // For CoolLEDU (non-CoolLEDMX/CoolLEDUX), use standard format (iOS lines 1390-1401)
        // 9. Time interval - 2 bytes (iOS line 1393)
        contentData.addAll(getHexListStringForIntWithTwo(animation.getTimeIntervalAnimation()));

        // Convert pixel data to hex string for length calculation
        // Use compressed pixel data format (same as graffiti)
        List<String> pixelData = new ArrayList<>();
        if (animation.getDataAnimation() != null) {
            for (List<List<List<Float>>> frameData : animation.getDataAnimation()) {
                pixelData.addAll(convertPixelDataToHexListCompressed(frameData));
            }
        }

        // 10. Pixel data total length - 4 bytes (iOS lines 1396-1399)
        int charsTotalLength = pixelData.size();
        contentData.addAll(getHexListStringForIntWithFour(charsTotalLength));

        // 11. Pixel data (iOS line 1404)
        contentData.addAll(pixelData);

        // 0. Prepend 4-byte total length (content size + 4 bytes for this length field)
        // iOS lines 1406-1408: "0.拼接4个字节该段内容所有数据的总长度"
        List<String> result = new ArrayList<>();
        result.addAll(getHexListStringForIntWithFour(contentData.size() + 4));
        result.addAll(contentData);

        Log.d(TAG, "[ANIMATION_DATA] Total size with 4-byte prefix: " + result.size() + " bytes");
        Log.d(TAG, "[ANIMATION_DATA] Content size (without prefix): " + contentData.size() + " bytes");
        Log.d(TAG, "[ANIMATION_DATA] Pixel data size: " + pixelData.size() + " bytes");
        Log.d(TAG, "[ANIMATION_DATA] Frame count: " + (animation.getDataAnimation() != null ? animation.getDataAnimation().size() : 0));

        return result;
    }

    /**
     * Generate text content data (type 01) with per-character 1-bit lattice rendering.
     * Port of iOS JTTool.m getItemWordContent (lines 274-803)
     *
     * Each character is individually rendered to a bitmap, converted to 1-bit lattice,
     * and packed into hex. The display firmware handles scrolling natively.
     * This replaces the old approach of rendering the entire text to a 160px bitmap.
     */
    private static List<String> getDataWithTextContent(ColorTextModel32 text) {
        int height = text.getHeightData();
        int fontSpace = (text.getFontSpace() == 0) ? 1 : text.getFontSpace();
        boolean bold = text.isBold();

        Log.d(TAG, "[TEXT_CONTENT] Rendering per-character text: '" + text.getOriginText() +
                   "', height=" + height + ", bold=" + bold + ", fontSpace=" + fontSpace);

        // Render each character and build concatenated bitmap data
        StringBuilder sumCheckedString = new StringBuilder();
        StringBuilder wordsWidth = new StringBuilder();
        StringBuilder wordsColor = new StringBuilder();

        List<HLColorTextItem> textItems = text.getTextItems();
        if (textItems != null) {
            for (HLColorTextItem item : textItems) {
                String character = item.getText();
                if (character == null || character.equals("\n")) continue;

                // 1. Render character to 1-bit lattice
                int[][] lattice = renderCharacterToLattice(character, height, bold);

                // 2. Add font spacing (empty columns between characters)
                lattice = addFontSpacing(lattice, fontSpace, height);

                // 3. Convert to hex string
                String checkedString = latticeToCheckedString(lattice, height);

                // 4. Calculate column width for this character
                // iOS: currentLength = checkedString.length * ratioStringByte(height)
                float ratio = ratioStringByte(height);
                int charColumns = (int)(checkedString.length() * ratio);

                // Ensure wordsWidth uses 2-byte format if column count > 255
                String hexWidth = String.format("%02x", charColumns);
                if (hexWidth.length() % 2 != 0) {
                    hexWidth = "0" + hexWidth;
                }
                wordsWidth.append(hexWidth);
                wordsColor.append(getWordColor(item.getRgbString() != null ? item.getRgbString() : "255,255,255"));
                sumCheckedString.append(checkedString);

                Log.d(TAG, "[TEXT_CONTENT] Char '" + character + "': latticeWidth=" + (lattice.length) +
                           ", columns=" + charColumns + ", hexLen=" + checkedString.length());
            }
        }

        // Calculate total width in columns
        float ratio = ratioStringByte(height);
        int wordsLength = (int)(sumCheckedString.length() * ratio);

        Log.d(TAG, "[TEXT_CONTENT] Total: wordsLength=" + wordsLength +
                   " columns, sumCheckedString=" + sumCheckedString.length() + " hex chars");

        // Cache result for getDataWithCustomColorContent
        lastTextRenderResult = new TextRenderResult();
        lastTextRenderResult.sumCheckedString = sumCheckedString.toString();
        lastTextRenderResult.wordsLength = wordsLength;
        lastTextRenderResult.wordsWidth = wordsWidth.toString();
        lastTextRenderResult.wordsColor = wordsColor.toString();

        // Build type 01 block (iOS JTTool.m lines 688-798, CoolLEDU "else" branch)
        List<String> contentData = new ArrayList<>();

        // 1. Type = 01 (text/bitmap content)
        contentData.add("01");

        // 2. 7 reserved bytes
        for (int i = 0; i < 7; i++) contentData.add("00");

        // 3. coverType (1 byte)
        contentData.add(getHexStringForIntWithOneByte(text.getCoverType()));

        // 4. startCol (2 bytes)
        contentData.addAll(getHexListStringForIntWithTwo(text.getStartCol()));

        // 5. startRow (2 bytes)
        contentData.addAll(getHexListStringForIntWithTwo(text.getStartRow()));

        // 6. widthData (2 bytes)
        contentData.addAll(getHexListStringForIntWithTwo(text.getWidthData()));

        // 7. heightData (2 bytes)
        contentData.addAll(getHexListStringForIntWithTwo(text.getHeightData()));

        // 8. showModel (1 byte)
        contentData.add(getHexStringForIntWithOneByte(text.getShowModel()));

        // 9. speedData (1 byte) - iOS does NOT add +239 for text content type 01
        contentData.add(getHexStringForIntWithOneByte(text.getSpeedData()));

        // 10. stayTime (1 byte)
        contentData.add(getHexStringForIntWithOneByte(text.getStayTime()));

        // 11. charsTotalLength (4 bytes) = hex bytes of bitmap data
        // iOS: charsTotalLength = sumCheckedString.length * 0.5
        int charsTotalLength = sumCheckedString.length() / 2;
        contentData.addAll(getHexListStringForIntWithFour(charsTotalLength));

        // 12. Per-character bitmap data (sumCheckedString)
        String sumHex = sumCheckedString.toString();
        for (int i = 0; i < sumHex.length(); i += 2) {
            contentData.add(sumHex.substring(i, Math.min(i + 2, sumHex.length())));
        }

        // Prepend 4-byte total length (iOS line 797-798)
        List<String> result = new ArrayList<>();
        result.addAll(getHexListStringForIntWithFour(contentData.size() + 4));
        result.addAll(contentData);

        Log.d(TAG, "[TEXT_CONTENT] Type 01 block: totalSize=" + result.size() +
                   ", bitmapBytes=" + charsTotalLength);

        return result;
    }

    /**
     * Generate custom color content data (type 06)
     * Port of iOS JTTool.m getItemCustomColorContent (lines 1011-1072)
     * This block is sent BEFORE the text bitmap block when colorShowType=1
     *
     * Uses actual per-character widths and colors from lastTextRenderResult
     * (populated by getDataWithTextContent, which must be called first).
     */
    private static List<String> getDataWithCustomColorContent(ColorTextModel32 text) {
        List<String> contentData = new ArrayList<>();

        int wordCount = (text.getTextItems() != null) ? text.getTextItems().size() : 0;

        // Use cached render results from getDataWithTextContent
        int wordsLength = (lastTextRenderResult != null) ? lastTextRenderResult.wordsLength : 0;
        String wordsWidthHex = (lastTextRenderResult != null) ? lastTextRenderResult.wordsWidth : "";
        String wordsColorHex = (lastTextRenderResult != null) ? lastTextRenderResult.wordsColor : "";

        Log.d(TAG, "[CUSTOM_COLOR] wordCount=" + wordCount + ", wordsLength=" + wordsLength +
                   ", movespace=" + text.getMovespace());

        // 1. Type = 06 (custom color)
        contentData.add("06");

        // 2. 5 reserved bytes
        for (int i = 0; i < 5; i++) contentData.add("00");

        // 3. movespace (2 bytes)
        contentData.addAll(getHexListStringForIntWithTwo(text.getMovespace()));

        // 4. startCol (2 bytes)
        contentData.addAll(getHexListStringForIntWithTwo(text.getStartCol()));

        // 5. startRow (2 bytes)
        contentData.addAll(getHexListStringForIntWithTwo(text.getStartRow()));

        // 6. widthData (2 bytes)
        contentData.addAll(getHexListStringForIntWithTwo(text.getWidthData()));

        // 7. heightData (2 bytes)
        contentData.addAll(getHexListStringForIntWithTwo(text.getHeightData()));

        // 8. showModel (1 byte)
        contentData.add(getHexStringForIntWithOneByte(text.getShowModel()));

        // 9. speedData (1 byte)
        contentData.add(getHexStringForIntWithOneByte(text.getSpeedData()));

        // 10. stayTime (1 byte)
        contentData.add(getHexStringForIntWithOneByte(text.getStayTime()));

        // 11. reserved (1 byte)
        contentData.add("00");

        // 12. wordCount (2 bytes)
        contentData.addAll(getHexListStringForIntWithTwo(wordCount));

        // 13. wordsLength (2 bytes) - total columns all chars occupy
        contentData.addAll(getHexListStringForIntWithTwo(wordsLength));

        // 14. wordsWidth data (1 byte per char from render results)
        for (int i = 0; i < wordsWidthHex.length(); i += 2) {
            contentData.add(wordsWidthHex.substring(i, Math.min(i + 2, wordsWidthHex.length())));
        }

        // 15. wordsColor data (2 bytes per char from render results)
        for (int i = 0; i < wordsColorHex.length(); i += 2) {
            contentData.add(wordsColorHex.substring(i, Math.min(i + 2, wordsColorHex.length())));
        }

        // Prepend 4-byte total length
        List<String> result = new ArrayList<>();
        result.addAll(getHexListStringForIntWithFour(contentData.size() + 4));
        result.addAll(contentData);

        Log.d(TAG, "[CUSTOM_COLOR] Type 06 block: wordCount=" + wordCount +
                   ", wordsLength=" + wordsLength + ", totalSize=" + result.size());
        return result;
    }

    /**
     * Convert pixel data [column][row][rgb] to hex string list
     * RGB values are 0.0-1.0 floats, converted to 0-255 integers
     */
    private static List<String> convertPixelDataToHexList(List<List<List<Float>>> pixelData) {
        List<String> result = new ArrayList<>();

        if (pixelData == null || pixelData.isEmpty()) {
            return result;
        }

        // Column-major order: for each column, for each row, R G B
        for (List<List<Float>> columnData : pixelData) {
            for (List<Float> pixelRgb : columnData) {
                if (pixelRgb != null && pixelRgb.size() >= 3) {
                    int r = (int) (pixelRgb.get(0) * 255.0f);
                    int g = (int) (pixelRgb.get(1) * 255.0f);
                    int b = (int) (pixelRgb.get(2) * 255.0f);
                    result.add(String.format("%02x", r));
                    result.add(String.format("%02x", g));
                    result.add(String.format("%02x", b));
                }
            }
        }

        return result;
    }

    /**
     * Convert float color value (0.0-1.0) to 4-bit value (0-15)
     * Matches iOS HLUtils colorExchangeFloat implementation
     * iOS comment: "+239解决速度变化非线性，前期滑动速度不明显"
     */
    private static int colorExchangeFloat(float colorValue) {
        float convertedValue = colorValue * 255;
        int trueValue;

        if (convertedValue >= 238) {
            trueValue = 15;  // Max brightness
        } else if (convertedValue <= 30) {
            trueValue = 0;   // Min brightness
        } else {
            trueValue = (int)((convertedValue - 30) / 15) + 1;
        }

        return trueValue;
    }

    /**
     * Convert pixel data to COMPRESSED hex format (2 bytes per pixel) for graffiti
     * Format: [R:4bit in 8bit][G:4bit|B:4bit]
     * This matches iOS implementation for CoolLEDU devices
     */
    private static List<String> convertPixelDataToHexListCompressed(List<List<List<Float>>> pixelData) {
        List<String> result = new ArrayList<>();

        if (pixelData == null || pixelData.isEmpty()) {
            return result;
        }

        // Column-major order: for each column, for each row
        for (List<List<Float>> columnData : pixelData) {
            for (List<Float> pixelRgb : columnData) {
                if (pixelRgb != null && pixelRgb.size() >= 3) {
                    int r = colorExchangeFloat(pixelRgb.get(0));
                    int g = colorExchangeFloat(pixelRgb.get(1));
                    int b = colorExchangeFloat(pixelRgb.get(2));

                    // First byte: R (4-bit value in 8-bit byte)
                    result.add(String.format("%02x", r));

                    // Second byte: G (high 4 bits) + B (low 4 bits)
                    result.add(String.format("%02x", (g << 4) | b));
                }
            }
        }

        return result;
    }

    /**
     * Generate begin packet (initial handshake)
     * Format: [02][CRC 4B][length 4B][index 1B][count 1B]
     * iOS: 000B 02 <CRC8hex> <LENGTH8hex> <INDEX2hex> <COUNT2hex>
     */
    private static List<String> getStartDataForProgram(List<String> programData, int index, int count) {
        List<String> result = new ArrayList<>();

        // Command byte
        result.add("02");

        // CRC32 checksum (4 bytes) - calculated on UNCOMPRESSED data
        List<String> crcBytes = getCrcCode(programData);
        result.addAll(crcBytes);

        // Data length (4 bytes) - UNCOMPRESSED data length
        List<String> lengthBytes = getHexListStringForIntWithFourByte(programData);
        result.addAll(lengthBytes);

        // Program index (1 byte)
        result.add(getHexStringForIntWithOneByte(index));

        // Total program count (1 byte)
        result.add(getHexStringForIntWithOneByte(count));

        // DEBUG: Log the begin packet structure BEFORE framing
        Log.d(TAG, "[BEGIN_PACKET] ===== BEGIN PACKET STRUCTURE (before framing) =====");
        Log.d(TAG, "[BEGIN_PACKET] programData size: " + programData.size() + " bytes");
        Log.d(TAG, "[BEGIN_PACKET] CRC32: " + String.join("", crcBytes) + " (4 bytes)");
        Log.d(TAG, "[BEGIN_PACKET] Length: " + String.join("", lengthBytes) + " = " + programData.size() + " bytes");
        Log.d(TAG, "[BEGIN_PACKET] Index: " + getHexStringForIntWithOneByte(index));
        Log.d(TAG, "[BEGIN_PACKET] Count: " + getHexStringForIntWithOneByte(count));
        Log.d(TAG, "[BEGIN_PACKET] Raw packet (11 bytes): " + String.join(" ", result));
        Log.d(TAG, "[BEGIN_PACKET] ===== END BEGIN PACKET STRUCTURE =====");

        // Add framing (0x01 start, length, escaped data, 0x03 end)
        List<String> framedPacket = getSendDataWithInfo(result);

        Log.d(TAG, "[BEGIN_PACKET] Framed packet: " + String.join(" ", framedPacket));

        return framedPacket;
    }

    /**
     * Split data into packets and add protocol headers
     * Each packet: [type][reserved][total length 4B][index 2B][chunk size 2B][data...][checksum]
     * Max packet size: 1024 bytes of data
     * iOS format: [length 2B] [type] [00] [totalLen 4B] [index 2B] [chunkLen 2B] [data] [xor checksum 1B]
     */
    private static List<List<String>> getDataPacket(List<String> inputData, String type) {
        List<List<String>> result = new ArrayList<>();

        // Split into 1024-byte chunks (matching iOS fontsType:32)
        int maxChunkSize = 1024;
        int totalSize = inputData.size();
        int packetCount = (int) Math.ceil((double) totalSize / maxChunkSize);

        Log.d(TAG, "[DATA_PACKET] ===== DATA PACKET GENERATION =====");
        Log.d(TAG, "[DATA_PACKET] Compressed data size: " + totalSize + " bytes");
        Log.d(TAG, "[DATA_PACKET] Chunk size: " + maxChunkSize + ", Total packets: " + packetCount);

        for (int i = 0; i < packetCount; i++) {
            int start = i * maxChunkSize;
            int end = Math.min(start + maxChunkSize, totalSize);
            List<String> chunk = inputData.subList(start, end);

            List<String> packet = new ArrayList<>();
            packet.add("00");  // Reserved

            // Total data length (4 bytes)
            packet.addAll(getHexListStringForIntWithFourByte(inputData));

            // Packet index (2 bytes)
            packet.addAll(getHexListStringForIntWithTwo(i));

            // Chunk size (2 bytes)
            packet.addAll(getHexListStringForIntWithTwo(chunk.size()));

            // Chunk data
            packet.addAll(chunk);

            // Checksum (XOR of all bytes, 1 byte)
            List<String> checksum = convertEnd(packet);
            packet.addAll(checksum);

            // Add type byte and framing
            List<String> finalPacket = new ArrayList<>();
            finalPacket.add(type);
            finalPacket.addAll(packet);

            // Log packet structure for first packet
            if (i == 0) {
                Log.d(TAG, "[DATA_PACKET] Packet " + i + " structure (before framing):");
                Log.d(TAG, "[DATA_PACKET]   Type: " + type);
                Log.d(TAG, "[DATA_PACKET]   Reserved: 00");
                Log.d(TAG, "[DATA_PACKET]   Total length: " + String.join("", getHexListStringForIntWithFourByte(inputData)) + " = " + totalSize);
                Log.d(TAG, "[DATA_PACKET]   Index: " + String.join("", getHexListStringForIntWithTwo(i)));
                Log.d(TAG, "[DATA_PACKET]   Chunk size: " + String.join("", getHexListStringForIntWithTwo(chunk.size())) + " = " + chunk.size());
                Log.d(TAG, "[DATA_PACKET]   XOR Checksum: " + checksum.get(0));
                // Show first 20 bytes of chunk data
                StringBuilder chunkHex = new StringBuilder();
                for (int j = 0; j < Math.min(20, chunk.size()); j++) {
                    chunkHex.append(chunk.get(j)).append(" ");
                }
                Log.d(TAG, "[DATA_PACKET]   Chunk data (first 20 bytes): " + chunkHex.toString());
            }

            result.add(getSendDataWithInfo(finalPacket));
        }

        Log.d(TAG, "[DATA_PACKET] ===== END DATA PACKET GENERATION =====");

        return result;
    }

    /**
     * Add protocol framing: [0x01][escaped(length + data)][0x03]
     * CRITICAL FIX: Length bytes MUST be escaped together with data!
     * Manufacturer code escapes [length + data] as a unit, not separately.
     */
    private static List<String> getSendDataWithInfo(List<String> data) {
        List<String> result = new ArrayList<>();

        // Start byte
        result.add("01");

        // Combine length + data, then escape BOTH together (matches manufacturer implementation)
        List<String> tempResult = new ArrayList<>();
        tempResult.addAll(getDataStringLength(data));  // Length (2 bytes) - unescaped original data length
        tempResult.addAll(data);                        // Data bytes
        result.addAll(convertData(tempResult, 0));      // Escape the combined length+data

        // End byte
        result.add("03");

        return result;
    }

    /**
     * Escape data bytes: 0x01-0x03 become [0x02, byte^0x04]
     */
    private static List<String> convertData(List<String> data, int index) {
        List<String> result = new ArrayList<>();

        for (String hexStr : data) {
            int value = Integer.parseInt(hexStr, 16);

            if (value >= 0x01 && value <= 0x03) {
                // Escape: add 0x02 prefix and XOR with 0x04
                result.add("02");
                result.add(String.format("%02x", value ^ 0x04));
            } else {
                result.add(hexStr);
            }
        }

        return result;
    }

    /**
     * Calculate length of data after escaping
     */
    private static List<String> getDataStringLength(List<String> data) {
        // iOS returns the UNESCAPED data length, not the escaped length
        // The length field represents the original data size before escaping
        int length = data.size();
        return getHexListStringForIntWithTwo(length);
    }

    /**
     * Calculate CRC32 checksum (4 bytes)
     */
    public static List<String> getCrcCode(List<String> data) {
        byte[] bytes = new byte[data.size()];
        for (int i = 0; i < data.size(); i++) {
            bytes[i] = (byte) Integer.parseInt(data.get(i), 16);
        }

        int crc = Crc32Algorithm.getCrc32CheckCode(bytes);

        // Return 4 bytes (full CRC32 - matches iOS %08x format)
        List<String> result = new ArrayList<>();
        result.add(String.format("%02x", (crc >> 24) & 0xFF));
        result.add(String.format("%02x", (crc >> 16) & 0xFF));
        result.add(String.format("%02x", (crc >> 8) & 0xFF));
        result.add(String.format("%02x", crc & 0xFF));
        return result;
    }

    /**
     * Generate display toggle command with simple escaping (NO LZSS compression)
     * iOS: raw "00020501" becomes "0100020605020503" after escaping+framing
     * Unlike program data, simple commands use direct escaping without LZSS
     * @param rawCommand Raw command bytes [length 2B][command 05][value]
     * @return Framed command ready to send via BLE
     */
    public static List<String> getDisplayToggleCommand(List<String> rawCommand) {
        // Simple framing with escaping: [0x01][escaped data][0x03]
        // Escape bytes 0x01-0x03: prepend 0x02 and XOR with 0x04
        List<String> result = new ArrayList<>();
        result.add("01");  // Start byte

        // Escape each byte in rawCommand
        for (String hexStr : rawCommand) {
            int value = Integer.parseInt(hexStr, 16);
            if (value >= 0x01 && value <= 0x03) {
                // Escape: add 0x02 prefix and XOR with 0x04
                result.add("02");
                result.add(String.format("%02x", value ^ 0x04));
            } else {
                result.add(hexStr);
            }
        }

        result.add("03");  // End byte
        return result;
    }

    /**
     * Calculate checksum (XOR of all bytes, 1 byte)
     * Mirrors iOS verifyStringWith implementation
     */
    private static List<String> convertEnd(List<String> data) {
        // Calculate XOR checksum (matches iOS verifyStringWith implementation)
        int xorResult = 0;
        for (String hexStr : data) {
            xorResult ^= Integer.parseInt(hexStr, 16);
        }
        // Return as single byte (iOS returns %02x)
        return Arrays.asList(String.format("%02x", xorResult & 0xFF));
    }

    // Hex conversion utilities
    private static String getHexStringForIntWithOneByte(int value) {
        return String.format("%02x", value & 0xFF);
    }

    private static List<String> getHexListStringForWithOneByte(int value) {
        return Arrays.asList(getHexStringForIntWithOneByte(value));
    }

    private static List<String> getHexListStringForIntWithTwo(int value) {
        List<String> result = new ArrayList<>();
        result.add(String.format("%02x", (value >> 8) & 0xFF));
        result.add(String.format("%02x", value & 0xFF));
        return result;
    }

    private static List<String> getHexListStringForIntWithFour(int value) {
        List<String> result = new ArrayList<>();
        // Big-endian byte order (matches iOS %08x format)
        result.add(String.format("%02x", (value >> 24) & 0xFF));  // Most significant byte first
        result.add(String.format("%02x", (value >> 16) & 0xFF));
        result.add(String.format("%02x", (value >> 8) & 0xFF));
        result.add(String.format("%02x", value & 0xFF));          // Least significant byte last
        return result;
    }

    private static List<String> getHexListStringForIntWithFourByte(List<String> data) {
        int length = data.size();
        return getHexListStringForIntWithFour(length);
    }

    /**
     * Parse notification response
     * Format: [type][reserved][index 2B][response code]
     */
    public static class NotificationResponse {
        public int type;
        public int packetIndex;
        public int responseCode;

        public boolean isSuccess() {
            return responseCode == RESPONSE_SUCCESS;
        }
    }

    /**
     * Parse BLE notification data
     */
    public static NotificationResponse parseNotificationResponse(byte[] data) {
        if (data == null || data.length < 5) {
            return null;
        }

        // Remove framing and unescape
        List<String> recovered = recoverData(data);

        if (recovered.size() < 5) {
            return null;
        }

        NotificationResponse response = new NotificationResponse();
        response.type = Integer.parseInt(recovered.get(0), 16);

        // Parse packet index (2 bytes)
        String indexHigh = recovered.get(2);
        String indexLow = recovered.get(3);
        response.packetIndex = Integer.parseInt(indexHigh + indexLow, 16);

        // Parse response code
        response.responseCode = Integer.parseInt(recovered.get(4), 16);

        return response;
    }

    /**
     * Unescape and remove framing from received data
     * PUBLIC: Also used by DisplayManagerBridge to parse device responses
     */
    public static List<String> recoverData(byte[] data) {
        List<String> hexList = new ArrayList<>();
        for (byte b : data) {
            hexList.add(String.format("%02x", b & 0xFF));
        }

        // Remove framing (0x01 start, 0x03 end)
        if (hexList.size() < 4) {
            return hexList;
        }

        List<String> targetData = hexList.subList(1, hexList.size() - 1);

        // Unescape data (reverse 0x02 escaping)
        List<String> result = new ArrayList<>();
        for (int i = 0; i < targetData.size(); i++) {
            if (!targetData.get(i).equals("02")) {
                result.add(targetData.get(i));
            } else if (i + 1 < targetData.size()) {
                // Unescape: XOR with 0x04
                int tempValue = Integer.parseInt(targetData.get(i + 1), 16);
                tempValue ^= 0x04;
                result.add(String.format("%02x", tempValue));
                i++;
            }
        }

        // Skip length bytes (first 2 bytes after unescaping)
        if (result.size() > 2) {
            return result.subList(2, result.size());
        }

        return result;
    }

    /**
     * Convert hex string list to byte array for BLE write
     */
    public static byte[] hexListToBytes(List<String> hexList) {
        byte[] bytes = new byte[hexList.size()];
        for (int i = 0; i < hexList.size(); i++) {
            bytes[i] = (byte) Integer.parseInt(hexList.get(i), 16);
        }
        return bytes;
    }

    // ============================================================================
    // Text Protocol Helpers - Per-character 1-bit lattice rendering
    // Ports iOS: generateDataFromImageFont, checkedStringWithLatticeArray,
    //            ratioStringByte, getWordColorFrom
    // ============================================================================

    /**
     * Render a single character to a 1-bit lattice array (column-major).
     * Port of iOS HLUtils generateDataFromImageFont (HLUtils.m:2063-2126)
     *
     * @return int[column][row] where each value is 0 (off) or 1 (on)
     */
    private static int[][] renderCharacterToLattice(String character, int height, boolean bold) {
        // Configure paint
        Paint paint = new Paint();
        paint.setAntiAlias(false); // No anti-aliasing for clean 1-bit output
        paint.setColor(Color.WHITE);
        paint.setTextSize(height);
        paint.setTypeface(bold ? Typeface.DEFAULT_BOLD : Typeface.DEFAULT);

        // Measure character width
        float charWidth = paint.measureText(character);
        int bitmapWidth = Math.max(1, (int) Math.ceil(charWidth));
        int bitmapHeight = height;

        // Create bitmap and canvas
        Bitmap bitmap = Bitmap.createBitmap(bitmapWidth, bitmapHeight, Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bitmap);
        canvas.drawColor(Color.BLACK);

        // Center character (matching iOS positioning)
        Paint.FontMetrics fm = paint.getFontMetrics();
        float textHeight = fm.descent - fm.ascent;
        float x = (bitmapWidth - charWidth) / 2.0f;
        float y = (bitmapHeight - textHeight) / 2.0f - fm.ascent;

        canvas.drawText(character, x, y, paint);

        // Convert to 1-bit lattice (column-major)
        // iOS threshold: RGB > 0.1 = 1
        int[][] lattice = new int[bitmapWidth][bitmapHeight];
        for (int col = 0; col < bitmapWidth; col++) {
            for (int row = 0; row < bitmapHeight; row++) {
                int pixel = bitmap.getPixel(col, row);
                float r = Color.red(pixel) / 255.0f;
                float g = Color.green(pixel) / 255.0f;
                float b = Color.blue(pixel) / 255.0f;
                lattice[col][row] = (r > 0.1f || g > 0.1f || b > 0.1f) ? 1 : 0;
            }
        }

        bitmap.recycle();
        return lattice;
    }

    /**
     * Add empty columns at the end of a lattice for inter-character spacing.
     * Port of iOS optArrayWithLatticeArray fontSpace handling.
     */
    private static int[][] addFontSpacing(int[][] lattice, int fontSpace, int height) {
        int origWidth = lattice.length;
        int newWidth = origWidth + fontSpace;
        int[][] result = new int[newWidth][height];

        for (int col = 0; col < origWidth; col++) {
            System.arraycopy(lattice[col], 0, result[col], 0, height);
        }
        // Remaining columns are 0 by default (empty/off)
        return result;
    }

    /**
     * Convert 1-bit lattice to hex string (MSB-first bit packing).
     * Port of iOS checkedStringWithLatticeArray (NSString+QCExtension.m:75-95)
     *
     * For each column, groups of 8 rows are packed into one byte:
     *   bit7 = first row in group, bit0 = 8th row in group.
     * For height=32: 4 bytes per column.
     */
    private static String latticeToCheckedString(int[][] lattice, int height) {
        StringBuilder result = new StringBuilder();
        int numColumns = lattice.length;
        int bytesPerColumn = (int) Math.ceil(height / 8.0);

        for (int col = 0; col < numColumns; col++) {
            for (int j = 0; j < bytesPerColumn; j++) {
                int sum = 0;
                for (int k = j * 8; k < (j + 1) * 8 && k < height; k++) {
                    // iOS: sum += value * pow(2, (j+1)*8 - 1 - k)
                    sum += lattice[col][k] * (1 << ((j + 1) * 8 - 1 - k));
                }
                result.append(String.format("%02x", sum));
            }
        }
        return result.toString();
    }

    /**
     * Convert "R,G,B" (0-255) color string to 2-byte CoolLEDU color format.
     * Port of iOS JTCommon getWordColorFrom for CoolLEDU (JTCommon.m:211-224)
     *
     * Format: byte0 = R(4-bit), byte1 = G(4-bit high) | B(4-bit low)
     */
    private static String getWordColor(String rgbString) {
        String[] parts = rgbString.split(",");
        float r = Float.parseFloat(parts[0].trim());
        float g = Float.parseFloat(parts[1].trim());
        float b = Float.parseFloat(parts[2].trim());

        int r4 = colorExchangeFloat(r / 255.0f);
        int g4 = colorExchangeFloat(g / 255.0f);
        int b4 = colorExchangeFloat(b / 255.0f);

        return String.format("%02x%02x", r4, g4 * 16 + b4);
    }

    /**
     * Ratio of hex string length to column count.
     * Port of iOS JTCommon ratioStringByte (JTCommon.m:2385-2406)
     *
     * For height=32: each column = 4 bytes = 8 hex chars, so ratio = 1/8
     * Usage: columns = hexString.length() * ratio
     */
    private static float ratioStringByte(int height) {
        switch (height) {
            case 12:
            case 16:
                return 1.0f / 4;
            case 20:
            case 24:
                return 1.0f / 6;
            case 32:
                return 1.0f / 8;
            case 48:
                return 1.0f / 12;
            default:
                return 1.0f / 8;
        }
    }
}

package com.mobilldriversprotocol;

import java.util.ArrayList;
import java.util.List;

/**
 * CoolLEDU Protocol Formatting Utilities
 * Extracted from CoolLED1248 Android app
 * Equivalent to iOS NSString+QCExtension
 * Copyright © JTKJ LED1248. All rights reserved.
 */
public class ProtocolUtils {
    
    /**
     * Convert int to hex string
     */
    public static String toHex(int value) {
        return String.format("%02X", value & 0xFF).toLowerCase();
    }
    
    /**
     * Convert hex string to integer
     */
    public static int numberWithHexString(String hexString) {
        return Integer.parseInt(hexString, 16);
    }
    
    /**
     * CoolLEDU protocol frame formatting - core method
     * Equivalent to iOS finalDataWith
     * Adds 0x01 start byte, data escaping, and 0x03 end byte
     */
    public static List<String> finalDataWith(List<String> dataString) {
        List<String> result = new ArrayList<>();
        result.add("01"); // Start byte
        
        // Process each hex byte and apply escaping
        for (String hexByte : dataString) {
            result.addAll(getData(hexByte));
        }
        
        result.add("03"); // End byte
        return result;
    }
    
    /**
     * Data transformation with special byte escaping
     * CoolLEDU protocol requires escaping 0x00-0x04 bytes
     * Equivalent to iOS getData method
     */
    public static List<String> getData(String hexByte) {
        List<String> result = new ArrayList<>();
        int value = Integer.parseInt(hexByte, 16);
        
        // CoolLEDU protocol: escape bytes 0x00-0x04
        if (value > 0x00 && value < 0x04) {
            result.add("02"); // Escape identifier
            value ^= 0x04;    // XOR operation
        }
        
        result.add(toHex(value));
        return result;
    }
    
    /**
     * Package data for CoolLEDU transmission (32-bit devices)
     * 4-byte total length + 2-byte current length + 1-byte packet ID + data
     */
    public static List<String> packageStringWith32Bit(List<String> dataString, 
                                                      int totalLength, 
                                                      int currentLength, 
                                                      int packageId) {
        List<String> result = new ArrayList<>();
        
        // 4-byte total length (little-endian)
        result.add(String.format("%02x", totalLength & 0xFF));
        result.add(String.format("%02x", (totalLength >> 8) & 0xFF));
        result.add(String.format("%02x", (totalLength >> 16) & 0xFF));
        result.add(String.format("%02x", (totalLength >> 24) & 0xFF));
        
        // 2-byte current length
        result.add(String.format("%02x", currentLength & 0xFF));
        result.add(String.format("%02x", (currentLength >> 8) & 0xFF));
        
        // 1-byte package ID
        result.add(String.format("%02x", packageId & 0xFF));
        
        // Add data
        result.addAll(dataString);
        
        return result;
    }
    
    /**
     * Create complete command packets for CoolLEDU devices
     * Equivalent to getPackageCommandsWithDataString from iOS
     */
    public static List<List<String>> getPackageCommandsWithDataString(List<String> dataString, int type) {
        List<List<String>> result = new ArrayList<>();
        
        int totalLength = dataString.size(); // Total data length in bytes
        int maxPacketSize = 1024; // 1024 bytes per packet for 32-bit devices
        
        // Single packet case
        if (totalLength <= maxPacketSize) {
            List<String> packet = new ArrayList<>();
            packet.add(String.format("%02x", type)); // Command type
            packet.addAll(packageStringWith32Bit(dataString, totalLength, totalLength, 0));
            
            // Add length prefix (4 bytes for 32-bit devices)
            List<String> lengthPrefix = new ArrayList<>();
            int packetLength = packet.size();
            lengthPrefix.add(String.format("%02x", packetLength & 0xFF));
            lengthPrefix.add(String.format("%02x", (packetLength >> 8) & 0xFF));
            lengthPrefix.add(String.format("%02x", (packetLength >> 16) & 0xFF));
            lengthPrefix.add(String.format("%02x", (packetLength >> 24) & 0xFF));
            
            List<String> finalPacket = new ArrayList<>();
            finalPacket.addAll(lengthPrefix);
            finalPacket.addAll(packet);
            
            result.add(finalDataWith(finalPacket));
            return result;
        }
        
        // Multiple packets case
        int fullPackets = totalLength / maxPacketSize;
        int remainder = totalLength % maxPacketSize;
        
        // Full packets
        for (int i = 0; i < fullPackets; i++) {
            int start = i * maxPacketSize;
            int end = start + maxPacketSize;
            List<String> subData = dataString.subList(start, end);
            
            List<String> packet = new ArrayList<>();
            packet.add(String.format("%02x", type));
            packet.addAll(packageStringWith32Bit(subData, totalLength, maxPacketSize, i));
            
            List<String> lengthPrefix = new ArrayList<>();
            int packetLength = packet.size();
            lengthPrefix.add(String.format("%02x", packetLength & 0xFF));
            lengthPrefix.add(String.format("%02x", (packetLength >> 8) & 0xFF));
            lengthPrefix.add(String.format("%02x", (packetLength >> 16) & 0xFF));
            lengthPrefix.add(String.format("%02x", (packetLength >> 24) & 0xFF));
            
            List<String> finalPacket = new ArrayList<>();
            finalPacket.addAll(lengthPrefix);
            finalPacket.addAll(packet);
            
            result.add(finalDataWith(finalPacket));
        }
        
        // Remainder packet
        if (remainder > 0) {
            int start = fullPackets * maxPacketSize;
            List<String> subData = dataString.subList(start, dataString.size());
            
            List<String> packet = new ArrayList<>();
            packet.add(String.format("%02x", type));
            packet.addAll(packageStringWith32Bit(subData, totalLength, remainder, fullPackets));
            
            List<String> lengthPrefix = new ArrayList<>();
            int packetLength = packet.size();
            lengthPrefix.add(String.format("%02x", packetLength & 0xFF));
            lengthPrefix.add(String.format("%02x", (packetLength >> 8) & 0xFF));
            lengthPrefix.add(String.format("%02x", (packetLength >> 16) & 0xFF));
            lengthPrefix.add(String.format("%02x", (packetLength >> 24) & 0xFF));
            
            List<String> finalPacket = new ArrayList<>();
            finalPacket.addAll(lengthPrefix);
            finalPacket.addAll(packet);
            
            result.add(finalDataWith(finalPacket));
        }
        
        return result;
    }
    
    /**
     * Simple checksum calculation
     */
    public static String verifyStringWith(List<String> data) {
        int sum = 0;
        for (String hex : data) {
            sum += Integer.parseInt(hex, 16);
        }
        sum = sum % 256;
        return String.format("%02x", sum);
    }
    
    /**
     * Convert byte array to hex string list
     */
    public static List<String> byteArrayToHexList(byte[] bytes) {
        List<String> result = new ArrayList<>();
        for (byte b : bytes) {
            result.add(String.format("%02x", b & 0xFF));
        }
        return result;
    }
    
    /**
     * Convert hex string list to byte array
     */
    public static byte[] hexListToByteArray(List<String> hexList) {
        byte[] result = new byte[hexList.size()];
        for (int i = 0; i < hexList.size(); i++) {
            result[i] = (byte) Integer.parseInt(hexList.get(i), 16);
        }
        return result;
    }
    
    /**
     * Join hex string list into single hex string
     */
    public static String joinHexList(List<String> hexList) {
        StringBuilder sb = new StringBuilder();
        for (String hex : hexList) {
            sb.append(hex);
        }
        return sb.toString();
    }
}
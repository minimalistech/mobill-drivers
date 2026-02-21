package com.mobilldriversprotocol.models;

/**
 * HLColorTextItem - Individual text character item
 * Port from iOS HLColorTextItem.h
 * Copyright © 2024 Mobill. All rights reserved.
 */
public class HLColorTextItem {

    // Item type (0=text, other values for emojis, etc.)
    private int itemType;

    // The text character
    private String text;

    // RGB color string (e.g., "255,0,0" for red)
    private String rgbString;

    // Language type (0=general, 1=Thai, 2=Hindi, 3=Arabic)
    private int languageType;

    // Constructor
    public HLColorTextItem() {
        this.itemType = 0;
        this.languageType = 0;
    }

    // Getters and Setters
    public int getItemType() {
        return itemType;
    }

    public void setItemType(int itemType) {
        this.itemType = itemType;
    }

    public String getText() {
        return text;
    }

    public void setText(String text) {
        this.text = text;
    }

    public String getRgbString() {
        return rgbString;
    }

    public void setRgbString(String rgbString) {
        this.rgbString = rgbString;
    }

    public int getLanguageType() {
        return languageType;
    }

    public void setLanguageType(int languageType) {
        this.languageType = languageType;
    }
}

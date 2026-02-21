package com.mobilldriversprotocol.models;

import java.util.List;

/**
 * ColorTextModel32 - Text Content Data Format
 * Port from iOS ColorTextModel32.h
 * Copyright © 2024 Mobill. All rights reserved.
 */
public class ColorTextModel32 {

    // Original text string
    private String originText;

    // Array of individual text items (characters)
    private List<HLColorTextItem> textItems;

    // Bold text
    private boolean bold;

    // Rotation degrees (0=0°, 1=90°, 2=180°, 3=270°)
    private int degree;

    // Font size (12, 14, 16, 24, 36; 0=auto-fit)
    private int font;

    // Auto-fit font size when font=0
    private int fontDefaultFit;

    // Font spacing (1-8)
    private int fontSpace;

    // Mirror effect
    private boolean isMirror;

    // Content display mixing mode with other layers
    private int coverType;

    // Content display starting row
    private int startRow;

    // Content display starting column
    private int startCol;

    // Content display width
    private int widthData;

    // Content display height
    private int heightData;

    // Display mode (1=static, 2=left scroll, 3=right scroll, etc.)
    private int showModel;

    // Display speed (speed for the display mode)
    private int speedData;

    // Stay time (pause time after one screen is displayed)
    private int stayTime;

    // Move spacing
    private int movespace;

    // Text color effect type (0=none, 1=custom, 2=dazzle)
    private int colorShowType;

    // Dazzle effect parameters
    private int dazzleShowModel;
    private int dazzleSpeedData;
    private int dazzleShowModelDirection;
    private int dazzleIndexSelect;
    private String dazzleType;
    private int dazzleTypeLength;

    // Edge/border parameters
    private boolean isEdge;
    private int coverTypeEdge;
    private int startRowEdge;
    private int startColEdge;
    private int widthDataEdge;
    private int heightDataEdge;
    private int showModelEdge;
    private int speedDataEdge;
    private int heightEdge;
    private int edgingIndexSelect;
    private String edgeContent;
    private int edgelenght;

    // Item content count
    private int itemContentCount;

    // Constructor
    public ColorTextModel32(int coverType, int startRow, int startCol, int width, int height) {
        this.coverType = coverType;
        this.startRow = startRow;
        this.startCol = startCol;
        this.widthData = width;
        this.heightData = height;
    }

    // Getters and Setters
    public String getOriginText() {
        return originText;
    }

    public void setOriginText(String originText) {
        this.originText = originText;
    }

    public List<HLColorTextItem> getTextItems() {
        return textItems;
    }

    public void setTextItems(List<HLColorTextItem> textItems) {
        this.textItems = textItems;
    }

    public boolean isBold() {
        return bold;
    }

    public void setBold(boolean bold) {
        this.bold = bold;
    }

    public int getDegree() {
        return degree;
    }

    public void setDegree(int degree) {
        this.degree = degree;
    }

    public int getFont() {
        return font;
    }

    public void setFont(int font) {
        this.font = font;
    }

    public int getFontDefaultFit() {
        return fontDefaultFit;
    }

    public void setFontDefaultFit(int fontDefaultFit) {
        this.fontDefaultFit = fontDefaultFit;
    }

    public int getFontSpace() {
        return fontSpace;
    }

    public void setFontSpace(int fontSpace) {
        this.fontSpace = fontSpace;
    }

    public boolean isMirror() {
        return isMirror;
    }

    public void setMirror(boolean mirror) {
        isMirror = mirror;
    }

    public int getCoverType() {
        return coverType;
    }

    public void setCoverType(int coverType) {
        this.coverType = coverType;
    }

    public int getStartRow() {
        return startRow;
    }

    public void setStartRow(int startRow) {
        this.startRow = startRow;
    }

    public int getStartCol() {
        return startCol;
    }

    public void setStartCol(int startCol) {
        this.startCol = startCol;
    }

    public int getWidthData() {
        return widthData;
    }

    public void setWidthData(int widthData) {
        this.widthData = widthData;
    }

    public int getHeightData() {
        return heightData;
    }

    public void setHeightData(int heightData) {
        this.heightData = heightData;
    }

    public int getShowModel() {
        return showModel;
    }

    public void setShowModel(int showModel) {
        this.showModel = showModel;
    }

    public int getSpeedData() {
        return speedData;
    }

    public void setSpeedData(int speedData) {
        this.speedData = speedData;
    }

    public int getStayTime() {
        return stayTime;
    }

    public void setStayTime(int stayTime) {
        this.stayTime = stayTime;
    }

    public int getMovespace() {
        return movespace;
    }

    public void setMovespace(int movespace) {
        this.movespace = movespace;
    }

    public int getColorShowType() {
        return colorShowType;
    }

    public void setColorShowType(int colorShowType) {
        this.colorShowType = colorShowType;
    }

    public boolean isEdge() {
        return isEdge;
    }

    public void setEdge(boolean edge) {
        isEdge = edge;
    }

    public int getItemContentCount() {
        return itemContentCount;
    }

    public void setItemContentCount(int itemContentCount) {
        this.itemContentCount = itemContentCount;
    }

    // Check if this is only an edge/border (no text content)
    public boolean isOnlyEdge() {
        return isEdge && (originText == null || originText.isEmpty());
    }
}

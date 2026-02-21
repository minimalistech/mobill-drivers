package com.mobilldriversprotocol.models;

import java.util.List;

/**
 * GraffitiModel32 - Graffiti/Image Content Data Format
 * Port from iOS GraffitiModel32.h
 * Copyright © 2024 Mobill. All rights reserved.
 */
public class GraffitiModel32 {

    // Graffiti pixel data - 2D array of color data
    private List<List<List<Float>>> dataGraffiti;

    // Content display mixing mode with other layers
    private int coverTypeGraffiti;

    // Content display starting row
    private int startRowGraffiti;

    // Content display starting column
    private int startColGraffiti;

    // Content display width
    private int widthDataGraffiti;

    // Content display height
    private int heightDataGraffiti;

    // Graffiti display mode (1=static, 2=left scroll, 3=right scroll, etc.)
    private int showModelGraffiti;

    // Graffiti display speed (speed for the display mode)
    private int speedDataGraffiti;

    // Graffiti stay time (pause time after one screen is displayed)
    private int stayTimeGraffiti;

    // Constructor
    public GraffitiModel32(int coverType, int startRow, int startCol, int width, int height) {
        this.coverTypeGraffiti = coverType;
        this.startRowGraffiti = startRow;
        this.startColGraffiti = startCol;
        this.widthDataGraffiti = width;
        this.heightDataGraffiti = height;
    }

    // Getters and Setters
    public List<List<List<Float>>> getDataGraffiti() {
        return dataGraffiti;
    }

    public void setDataGraffiti(List<List<List<Float>>> dataGraffiti) {
        this.dataGraffiti = dataGraffiti;
    }

    public int getCoverTypeGraffiti() {
        return coverTypeGraffiti;
    }

    public void setCoverTypeGraffiti(int coverTypeGraffiti) {
        this.coverTypeGraffiti = coverTypeGraffiti;
    }

    public int getStartRowGraffiti() {
        return startRowGraffiti;
    }

    public void setStartRowGraffiti(int startRowGraffiti) {
        this.startRowGraffiti = startRowGraffiti;
    }

    public int getStartColGraffiti() {
        return startColGraffiti;
    }

    public void setStartColGraffiti(int startColGraffiti) {
        this.startColGraffiti = startColGraffiti;
    }

    public int getWidthDataGraffiti() {
        return widthDataGraffiti;
    }

    public void setWidthDataGraffiti(int widthDataGraffiti) {
        this.widthDataGraffiti = widthDataGraffiti;
    }

    public int getHeightDataGraffiti() {
        return heightDataGraffiti;
    }

    public void setHeightDataGraffiti(int heightDataGraffiti) {
        this.heightDataGraffiti = heightDataGraffiti;
    }

    public int getShowModelGraffiti() {
        return showModelGraffiti;
    }

    public void setShowModelGraffiti(int showModelGraffiti) {
        this.showModelGraffiti = showModelGraffiti;
    }

    public int getSpeedDataGraffiti() {
        return speedDataGraffiti;
    }

    public void setSpeedDataGraffiti(int speedDataGraffiti) {
        this.speedDataGraffiti = speedDataGraffiti;
    }

    public int getStayTimeGraffiti() {
        return stayTimeGraffiti;
    }

    public void setStayTimeGraffiti(int stayTimeGraffiti) {
        this.stayTimeGraffiti = stayTimeGraffiti;
    }
}

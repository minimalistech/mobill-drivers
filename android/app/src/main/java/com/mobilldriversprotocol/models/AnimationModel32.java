package com.mobilldriversprotocol.models;

import java.util.List;

/**
 * AnimationModel32 - Animation Content Data Format
 * Port from iOS AnimationModel32.h
 * Copyright © 2024 Mobill. All rights reserved.
 */
public class AnimationModel32 {

    // Animation content data - array of frames, each frame is a 2D array
    private List<List<List<List<Float>>>> dataAnimation;

    // Individual display time for each frame
    private List<Integer> frameEveInterval;

    // Content display mixing mode with other layers
    private int coverTypeAnimation;

    // Content display starting row
    private int startRowAnimation;

    // Content display starting column
    private int startColAnimation;

    // Content display width
    private int widthDataAnimation;

    // Content display height
    private int heightDataAnimation;

    // Display interval time between each frame (longer = slower animation)
    private int timeIntervalAnimation;

    // Constructor
    public AnimationModel32(int coverType, int startRow, int startCol, int width, int height) {
        this.coverTypeAnimation = coverType;
        this.startRowAnimation = startRow;
        this.startColAnimation = startCol;
        this.widthDataAnimation = width;
        this.heightDataAnimation = height;
    }

    // Getters and Setters
    public List<List<List<List<Float>>>> getDataAnimation() {
        return dataAnimation;
    }

    public void setDataAnimation(List<List<List<List<Float>>>> dataAnimation) {
        this.dataAnimation = dataAnimation;
    }

    public List<Integer> getFrameEveInterval() {
        return frameEveInterval;
    }

    public void setFrameEveInterval(List<Integer> frameEveInterval) {
        this.frameEveInterval = frameEveInterval;
    }

    public int getCoverTypeAnimation() {
        return coverTypeAnimation;
    }

    public void setCoverTypeAnimation(int coverTypeAnimation) {
        this.coverTypeAnimation = coverTypeAnimation;
    }

    public int getStartRowAnimation() {
        return startRowAnimation;
    }

    public void setStartRowAnimation(int startRowAnimation) {
        this.startRowAnimation = startRowAnimation;
    }

    public int getStartColAnimation() {
        return startColAnimation;
    }

    public void setStartColAnimation(int startColAnimation) {
        this.startColAnimation = startColAnimation;
    }

    public int getWidthDataAnimation() {
        return widthDataAnimation;
    }

    public void setWidthDataAnimation(int widthDataAnimation) {
        this.widthDataAnimation = widthDataAnimation;
    }

    public int getHeightDataAnimation() {
        return heightDataAnimation;
    }

    public void setHeightDataAnimation(int heightDataAnimation) {
        this.heightDataAnimation = heightDataAnimation;
    }

    public int getTimeIntervalAnimation() {
        return timeIntervalAnimation;
    }

    public void setTimeIntervalAnimation(int timeIntervalAnimation) {
        this.timeIntervalAnimation = timeIntervalAnimation;
    }

    // Additional getters for protocol encoding
    public int getShowModelAnimation() {
        return 0; // Default value - customize based on your animation model
    }

    public int getSpeedDataAnimation() {
        return timeIntervalAnimation; // Speed is related to time interval
    }

    public int getStayTimeAnimation() {
        return 0; // Default value - customize based on your animation model
    }
}

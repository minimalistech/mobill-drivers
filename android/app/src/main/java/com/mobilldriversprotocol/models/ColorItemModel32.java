package com.mobilldriversprotocol.models;

import java.util.List;

/**
 * ColorItemModel32 - Program Item Container
 * Port from iOS ColorItemModel32.h
 * This is the top-level container for a program that can contain text, graffiti, or animation
 * Copyright © 2024 Mobill. All rights reserved.
 */
public class ColorItemModel32 {

    // Timestamp in milliseconds (used as ID when needed)
    private long timestampInMilliseconds;

    // Device identifier combining device type and resolution (e.g., "016016096")
    private String itemDeviceIdentify;

    // Number of content items this program contains
    private int itemContentCount;

    // How many times to show this program before switching to next (in multi-program scenarios)
    private int itemShowTime;

    // Whether this program is selected (UI flag)
    private boolean isSelected;

    // Selection index number
    private int selectIndex;

    // Selected state flag for driving mode
    private boolean isSelectedState;

    // Program name
    private String itemName;

    /**
     * Template type (masterplateCaseType):
     * For 32-row screens:
     *   1 = 1 line of text
     *   2 = 2 lines of text
     *   3 = Left image + right 1 line text
     *   4 = Left image + right 2 lines text
     *   5 = Left 1 line text + right image
     *   6 = Left 2 lines text + right image
     *   7 = Static graffiti/image (full screen)
     *   8 = Animation (full screen)
     *
     * For 16-row screens:
     *   1 = 1 line of text
     *   2 = Static graffiti/image (full screen)
     *   3 = Animation (full screen)
     *   4 = Left image + right 1 line text
     *   5 = Left 1 line text + right image
     *
     * For 48-row screens:
     *   1 = 1 line of text
     *   2 = 2 lines of 24-row text each
     *   3 = 2 lines (top 16-row + bottom 32-row)
     *   4 = 2 lines (top 32-row + bottom 16-row)
     *   5 = 3 lines of 16-row text each
     */
    private int masterplateCaseType;

    // Array of ColorTextModel32 (text content)
    private List<ColorTextModel32> colorTextModel32Arr;

    // Array of GraffitiModel32 (graffiti/image content)
    private List<GraffitiModel32> graffitiModel32Arr;

    // Array of AnimationModel32 (animation content)
    private List<AnimationModel32> animationModel32Arr;

    // Constructor
    public ColorItemModel32() {
        this.timestampInMilliseconds = System.currentTimeMillis();
    }

    // Getters and Setters
    public long getTimestampInMilliseconds() {
        return timestampInMilliseconds;
    }

    public void setTimestampInMilliseconds(long timestampInMilliseconds) {
        this.timestampInMilliseconds = timestampInMilliseconds;
    }

    public String getItemDeviceIdentify() {
        return itemDeviceIdentify;
    }

    public void setItemDeviceIdentify(String itemDeviceIdentify) {
        this.itemDeviceIdentify = itemDeviceIdentify;
    }

    public int getItemContentCount() {
        return itemContentCount;
    }

    public void setItemContentCount(int itemContentCount) {
        this.itemContentCount = itemContentCount;
    }

    public int getItemShowTime() {
        return itemShowTime;
    }

    public void setItemShowTime(int itemShowTime) {
        this.itemShowTime = itemShowTime;
    }

    public boolean isSelected() {
        return isSelected;
    }

    public void setSelected(boolean selected) {
        isSelected = selected;
    }

    public int getSelectIndex() {
        return selectIndex;
    }

    public void setSelectIndex(int selectIndex) {
        this.selectIndex = selectIndex;
    }

    public boolean isSelectedState() {
        return isSelectedState;
    }

    public void setSelectedState(boolean selectedState) {
        isSelectedState = selectedState;
    }

    public String getItemName() {
        return itemName;
    }

    public void setItemName(String itemName) {
        this.itemName = itemName;
    }

    public int getMasterplateCaseType() {
        return masterplateCaseType;
    }

    public void setMasterplateCaseType(int masterplateCaseType) {
        this.masterplateCaseType = masterplateCaseType;
    }

    public List<ColorTextModel32> getColorTextModel32Arr() {
        return colorTextModel32Arr;
    }

    public void setColorTextModel32Arr(List<ColorTextModel32> colorTextModel32Arr) {
        this.colorTextModel32Arr = colorTextModel32Arr;
    }

    public List<GraffitiModel32> getGraffitiModel32Arr() {
        return graffitiModel32Arr;
    }

    public void setGraffitiModel32Arr(List<GraffitiModel32> graffitiModel32Arr) {
        this.graffitiModel32Arr = graffitiModel32Arr;
    }

    public List<AnimationModel32> getAnimationModel32Arr() {
        return animationModel32Arr;
    }

    public void setAnimationModel32Arr(List<AnimationModel32> animationModel32Arr) {
        this.animationModel32Arr = animationModel32Arr;
    }
}

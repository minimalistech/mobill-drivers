package com.mobilldriversprotocol;

import java.io.Serializable;
import java.util.List;

/**
 * Graffiti Model for CoolLEDU displays
 * Extracted from CoolLED1248 Android app
 * Copyright © JTKJ LED1248. All rights reserved.
 */
public class GraffitiModel implements Serializable {
    
    // 涂鸦点阵数据二维数组
    private List<List<Integer>> dataGraffiti;
    
    // 该内容显示的时候，和其他层级的内容的混合方式
    private int coverTypeGraffiti;
    
    // 该内容显示起始行
    private int startRowGraffiti;
    
    // 该内容显示起始列
    private int startColGraffiti;
    
    // 该内容显示宽度
    private int widthDataGraffiti;
    
    // 该内容显示高度
    private int heightDataGraffiti;
    
    // 涂鸦显示模式
    private int showModelGraffiti;
    
    // 涂鸦显示速度（显示模式的对应速度）
    private int speedDataGraffiti;
    
    // 涂鸦停留时间（一屏显示完成后的停留时间）
    private int stayTimeGraffiti;
    
    public GraffitiModel() {
        this(96, 16); // Default CoolLEDU 96x16
    }
    
    public GraffitiModel(int width, int height) {
        this.coverTypeGraffiti = 1;
        this.startRowGraffiti = 0;
        this.startColGraffiti = 0;
        this.widthDataGraffiti = width;
        this.heightDataGraffiti = height;
        this.showModelGraffiti = 1;
        this.speedDataGraffiti = 8;
        this.stayTimeGraffiti = 2;
    }
    
    // Getters and Setters
    public List<List<Integer>> getDataGraffiti() {
        return dataGraffiti;
    }
    
    public void setDataGraffiti(List<List<Integer>> dataGraffiti) {
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
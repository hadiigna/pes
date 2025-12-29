#pragma endian little

import std.io;
import type.base;

struct PESDescription {
    u8 lenDesign;
    char design[lenDesign];
    
    u8 lenCategory;
    char category[lenCategory];
    
    u8 lenAuthor;
    char author[lenAuthor];
    
    u8 lenKeyword;
    char keywords[lenKeyword];
    
    u8 lenComment;
    char comments[lenComment];
    
};

// PES Ver 6+?
struct PESFile {
    char pesHeader[4];
    char version[4];
    u32 pecOffset;
    
    u16 hoopSizeId;
    char unsure_subversion[2];
    
    PESDescription des;
    
    u16 unsure_optimizeHoopChange;
    u16 isDesignPageCustom;
    
    u16 hoopWidth;
    u16 hoopHeight;
    
    u16 isHoopRotate90deg;
    
    u16 designWidth_mm;
    u16 designHeight_mm;
    u16 designPageWidth_mm;
    u16 designPageHeight_mm;
    
    u16 unsure_designPropertySomething;
    u16 designPageBgColor;
    u16 designPageFgColor;
    u16 showGrid;
    u16 withAxes;
    u16 snapToGrid;
    u16 gridInterval;
    u16 UNKNOWN_1;
    u16 optimizeEntryExitPoints; //ぬい始終点最適化
    
    u8 fromImageStringLength;
    char path[fromImageStringLength];

   // Other things... CSewSeg... CEmbOne... looks like MFC CArchive format???


};

bitfield Stitch {
    bool isLongForm: 1;
    
    if(!isLongForm) {
        signed coord: 7;
    } else {
        controlCode: 3;
        signed coord: 12;
    }
};

struct PECStitch {
    // unit: 0.1 mm
    be Stitch dx;
    be Stitch dy;
} [[format("formatPecStitch")]];

fn formatPecStitchCommand(u8 controlCode) {
    str flags;
    if(controlCode & 0b100) {
        flags += "X "; //unknown flag
    }
    if(controlCode & 0b010) {
        flags += "TRIM ";
    }
    if(controlCode & 0b001) {
        flags += "JUMP ";
    }

// NOTE: Is this really a flag combination?

    flags += "L"; // long form indicator
    return flags;
};

fn formatPecStitch(PECStitch s) {
    str result;
    if(s.dx.isLongForm) { result += formatPecStitchCommand(s.dx.controlCode); }
    result += std::format("{}, ", s.dx.coord);
    if(s.dy.isLongForm) { result += formatPecStitchCommand(s.dy.controlCode); }
    result += std::format("{}", s.dy.coord);
    return result;
};

struct PECThumbnailImage {
// TODO
    u16 something;
};

struct PECFile {
    char label[19];
    char const_CarriageReturn;
    u8 UNKNOWN_2020_PATTERN[12];
    u16 UNKNOWN_FF_00;
    u8 thumbnailByteStride;
    u8 thumbnailHeightPx;
    u8 UNKNOWN_2020_PATTERN_2[12];
    u8 numColors_minusOne;
    u8 palleteIdx[1+numColors_minusOne];
    char PADDING_[462-numColors_minusOne];
    
    u16;
    u24 thumbnailOffset;
    char UNKNOWN_31FFF0[3];
    s16 width; // unit: 0.1mm
    s16 height;
    type::Hex<u16> UNKNOWN_11; // E0 01. Changing E0 will cause error. changing 01 doesn't do anything. unknown.
    type::Hex<u16> UNKNOWN_22; // B0 01. Maybe similar to thread change sequence FE >B0 [01/02]< ?? Changing this value seems to skip first thread color.
// So maybe E0 01 is a start sequence???
    //type::Hex<u32> UNKNOWN_33;

    PECStitch initStitch; // looks like plain JUMP x, y; so maybe should be consolidated into stitchList

   // Initial always looks like (JUMP x, JUMP y), (0, 0), ... Automatically added lock stitches (3 stitch) ..., (x1, y1), (x2, y2), ...

    PECStitch stitchList[while(!std::mem::reached(addressof(this) + thumbnailOffset + 512))];
    PECThumbnailImage thumbnailImage;
};

PESFile pes @ 0x00;
PECFile pec @ pes.pecOffset;

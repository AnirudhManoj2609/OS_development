#include <stdio.h>
#include <stdint.h>

typedef uint8_t bool;
#define true 1;
#define false 0;

typedef struct{

    uint8_t BootJumpInstruction[3];//3 bytes
    uint8_t bdb_oem[8];                    
    uint16_t bdb_bytes_per_sector;       
    uint8_t bdb_sectors_per_cluseter;   
    uint16_t bdb_reserved_sectors;       
    uint8_t bdb_fat_count;              
    uint16_t bdb_dir_entries_count;      
    uint16_t bdb_total_sectors;          
    uint8_t bdb_media_descriptor_type;  
    uint16_t bdb_sectors_per_fat;        
    uint16_t bdb_sectors_per_track;      
    uint16_t bdb_heads;
    uint32_t bdb_hidden_sectors;
    uint32_t bdb_large_sector_count;

    uint8_t ebr_drive_number;        
    uint8_t reserved;                
    uint8_t ebr_signature;              
    uint8_t ebr_volume_id; 
    uint8_t ebr_volume_label[11]; 
    uint8_t ebr_system_id[8];

}__attribute__((packed))BootSector;//removes padding
//since we used typedef this BootSector is the struct itself

BootSector g_bootsector;

bool readBootSector(FILE* disk){
    return fread(&g_bootsector,sizeof(g_bootsector),1,disk) > 0;
    //reads the datas in file to the memory in which g_bootsector is pointing

}

int main(int argc,char** argv){

    if(argc < 3){
        printf("Syntax: %s <disk image> <file name>\n",argv[0]);
        return -1;
    }
    FILE* disk = fopen(argv[1],"rb");
    if(!disk){
        fprintf(stderr,"Cannot open disk image %s!\n",argv[1]);
        return -1;
    }
    if(!readBootSector){
        fprintf(stderr,"Cannot read the boot sector!\n");
        return -2;
    }

    return 0;
}
/******************************************************************************
 *
 * Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Use of the Software is limited solely to applications:
 * (a) running on a Xilinx device, or
 * (b) that interact with a Xilinx device through a bus or interconnect.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
 * OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * Except as contained in this notice, the name of the Xilinx shall not be used
 * in advertising or otherwise to promote the sale, use or other dealings in
 * this Software without prior written authorization from Xilinx.
 *
 ******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include <stdint.h> // uint32정의
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h" //ctrl + space 자동완성
#include "sleep.h" // delay가능

typedef struct {
	volatile uint32_t DR;
	volatile uint32_t CR;
} GPIOA_TypeDef;

typedef struct {
	volatile uint32_t MODER;
	volatile uint32_t ODR;
	volatile uint32_t IDR;
} GPIOB_TypeDef;

#define GPIOA_BASEADDR 0x40000000U //unsigned
#define GPIOB_BASEADDR 0x44A00000U
//#define GPIO_DR *(volatile uint32_t*)(GPIO_BASEADDR + 0x00)
//#define GPIO_CR *(volatile uint32_t*)(GPIO_BASEADDR + 0x04) //offset
#define GPIOA ((GPIOA_TypeDef *)(GPIOA_BASEADDR))
#define GPIOB ((GPIOB_TypeDef *)(GPIOB_BASEADDR))

int switch_getstate(GPIOA_TypeDef *GPIOx, int bit);

int main() {
//    init_platform();
//
//    print("Hello World\n\r"); //uart
//    print("Successfully ran Hello World application\n\r"); //uart
//    cleanup_platform();
	GPIOA->CR = 0xff00; //f가 input임
	GPIOB->MODER = 0x0f; //f가 output 임
	uint8_t counter = 0;
	while (1) {


		if (switch_getstate(GPIOA, 13)) { //1이상이면 됨 13번쨰
			GPIOA->DR ^= 0xf0;
			xil_printf("counter : %d\n", counter++);
		}// 토글  : 원래꺼랑 깜빡이게
		if (switch_getstate(GPIOA, 8)){
			GPIOA->DR ^= 0x03;
		}
		if (GPIOB->IDR & (1U<<4)){
			GPIOA->DR ^=0x0C;
		}
		usleep(300000); //usecond단위
	}

	return 0;
}

int switch_getstate(GPIOA_TypeDef *GPIOx, int bit) {
	int temp;
	temp = GPIOx->DR & (1u << bit);
	return (temp == 0) ? 0 : 1;
}


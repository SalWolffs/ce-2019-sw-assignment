#include <stdio.h>
#include "../common/stm32wrapper.h"

extern uint32_t benchmark(uint32_t *cyccnt_address);

int main(void) {
	char outstr[0x80];
	unsigned int cost;

	clock_setup();
	gpio_setup();
	usart_setup(115200);

	SCS_DEMCR |= SCS_DEMCR_TRCENA;
	DWT_CYCCNT = 0;
	DWT_CTRL |= DWT_CTRL_CYCCNTENA;

	send_USART_str((unsigned char*)"\rbegin");

	cost = benchmark(&DWT_CYCCNT);

	sprintf(outstr, "cost: %x", cost);
	send_USART_str((unsigned char*)outstr);

	while (1) { }
	return 0;
}

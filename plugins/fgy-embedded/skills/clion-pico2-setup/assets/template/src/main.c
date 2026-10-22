#include <stdio.h>

#include "pico/stdlib.h"

#ifdef CYW43_WL_GPIO_LED_PIN
#include "pico/cyw43_arch.h"
#endif

#ifndef LED_DELAY_MS
#define LED_DELAY_MS 500
#endif

// Pico 2: the LED is on a regular GPIO. Pico 2 W: it is driven by the CYW43 chip.
static int led_init(void) {
#if defined(PICO_DEFAULT_LED_PIN)
    gpio_init(PICO_DEFAULT_LED_PIN);
    gpio_set_dir(PICO_DEFAULT_LED_PIN, GPIO_OUT);
    return PICO_OK;
#elif defined(CYW43_WL_GPIO_LED_PIN)
    return cyw43_arch_init();
#else
    return PICO_OK;
#endif
}

static void led_set(bool on) {
#if defined(PICO_DEFAULT_LED_PIN)
    gpio_put(PICO_DEFAULT_LED_PIN, on);
#elif defined(CYW43_WL_GPIO_LED_PIN)
    cyw43_arch_gpio_put(CYW43_WL_GPIO_LED_PIN, on);
#else
    (void) on;
#endif
}

int main(void) {
    stdio_init_all();

    int rc = led_init();
    hard_assert(rc == PICO_OK);

    uint32_t count = 0;
    while (true) {
        led_set(true);
        sleep_ms(LED_DELAY_MS);
        led_set(false);
        sleep_ms(LED_DELAY_MS);
        printf("@PROJECT@: tick %lu\n", (unsigned long) count++);
    }
}

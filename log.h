#ifndef LOG_H
#define LOG_H

#include <stdbool.h>
#include <stdint.h>

#define LOG_LENGTH 32

static char *log_strings[] = {
        "TIME: ",
        ". Since last: ",
		"Received packet of unknown variety.",
		"Wrote BAR 1 to: ",
		"Read BAR 1 of: "
};

#define LS_TIME 0
#define LS_TIME_DELTA 1
#define LS_RECV_UNKNOWN 2
#define LS_WRITE_BAR_1 3
#define LS_READ_BAR_1 4

enum log_newline {
	LOG_NO_NEWLINE,
	LOG_NEWLINE
};

enum log_item_format {
	LIF_NONE,
	LIF_BOOL,
	LIF_INT_32,
	LIF_UINT_32,
	LIF_UINT_32_HEX,
	LIF_INT_64,
	LIF_UINT_64,
	LIF_UINT_64_HEX
};

/*
 * Sets up the array of strings.
 */
void log_set_strings(char *strings[]);

/*
 * Logs where strings to print are stored in a table.
 * When printing, the string will be printed, followed by the data item.
 * If the string_id is -1, only the data item will be printed.
 * If the log_item_format is none, the data item will not be printed.
 *
 * If the act of logging fills the log buffer, the entire log is printed and
 * cleared.
 */
void log_log(int string_id, enum log_item_format format, uint64_t data_item,
	enum log_newline trailing_new_line);

/*
 * Prints and clears the log.
 */
void log_print();

/*
 * Sets the uint64_t pointer to the most recently logged data_item for a given
 * string_id. Return bool on success, or false if no matching string id is
 * found.
 */
bool log_last_data_for_string(int string_id, uint64_t *data);


static inline void
record_time()
{
       bool has_last_time;
       uint32_t time;
       uint64_t last_time;

       time = read_hw_counter();
       has_last_time = log_last_data_for_string(LS_TIME, &last_time);

       log_log(LS_TIME, LIF_UINT_32, time,
		   has_last_time ? LOG_NO_NEWLINE : LOG_NEWLINE);

       if (has_last_time) {
               log_log(LS_TIME_DELTA, LIF_INT_32, time - last_time,
				   LOG_NEWLINE);
       }
}



#endif

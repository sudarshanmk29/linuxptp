/*
 * Unity Unit Testing Framework
 * https://github.com/ThrowTheSwitch/Unity
 * 
 * Simplified version for linuxptp project
 */

#ifndef UNITY_H
#define UNITY_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

/* Test setup/teardown functions */
extern void setUp(void);
extern void tearDown(void);

/* Global test counter */
extern int unity_tests_run;
extern int unity_tests_failed;

#define TEST_ASSERT_EQUAL_INT(expected, actual) \
    do { \
        if ((expected) != (actual)) { \
            fprintf(stderr, "\n[FAIL] %s:%d: Expected %d but got %d\n", \
                    __FILE__, __LINE__, (int)(expected), (int)(actual)); \
            unity_tests_failed++; \
        } \
        unity_tests_run++; \
    } while(0)

#define TEST_ASSERT_EQUAL_UINT(expected, actual) \
    do { \
        if ((expected) != (actual)) { \
            fprintf(stderr, "\n[FAIL] %s:%d: Expected %u but got %u\n", \
                    __FILE__, __LINE__, (unsigned int)(expected), (unsigned int)(actual)); \
            unity_tests_failed++; \
        } \
        unity_tests_run++; \
    } while(0)

#define TEST_ASSERT_EQUAL(expected, actual) \
    TEST_ASSERT_EQUAL_INT(expected, actual)

#define TEST_ASSERT_EQUAL_STRING(expected, actual) \
    do { \
        if (strcmp((expected), (actual)) != 0) { \
            fprintf(stderr, "\n[FAIL] %s:%d: Expected \"%s\" but got \"%s\"\n", \
                    __FILE__, __LINE__, (expected), (actual)); \
            unity_tests_failed++; \
        } \
        unity_tests_run++; \
    } while(0)

#define TEST_ASSERT_NOT_NULL(ptr) \
    do { \
        if ((ptr) == NULL) { \
            fprintf(stderr, "\n[FAIL] %s:%d: Pointer is NULL\n", \
                    __FILE__, __LINE__); \
            unity_tests_failed++; \
        } \
        unity_tests_run++; \
    } while(0)

#define TEST_ASSERT_NULL(ptr) \
    do { \
        if ((ptr) != NULL) { \
            fprintf(stderr, "\n[FAIL] %s:%d: Pointer is not NULL\n", \
                    __FILE__, __LINE__); \
            unity_tests_failed++; \
        } \
        unity_tests_run++; \
    } while(0)

#define TEST_ASSERT_TRUE(condition) \
    do { \
        if (!(condition)) { \
            fprintf(stderr, "\n[FAIL] %s:%d: Condition is false\n", \
                    __FILE__, __LINE__); \
            unity_tests_failed++; \
        } \
        unity_tests_run++; \
    } while(0)

#define TEST_ASSERT_FALSE(condition) \
    do { \
        if (condition) { \
            fprintf(stderr, "\n[FAIL] %s:%d: Condition is true\n", \
                    __FILE__, __LINE__); \
            unity_tests_failed++; \
        } \
        unity_tests_run++; \
    } while(0)

#define TEST_ASSERT_EQUAL_MEMORY(expected, actual, len) \
    do { \
        if (memcmp((expected), (actual), (len)) != 0) { \
            fprintf(stderr, "\n[FAIL] %s:%d: Memory buffers differ\n", \
                    __FILE__, __LINE__); \
            unity_tests_failed++; \
        } \
        unity_tests_run++; \
    } while(0)

#define RUN_TEST(test_func) \
    do { \
        printf("Running %s...", #test_func); \
        fflush(stdout); \
        setUp(); \
        test_func(); \
        tearDown(); \
        printf(" OK\n"); \
    } while(0)

#define UNITY_BEGIN() \
    do { \
        unity_tests_run = 0; \
        unity_tests_failed = 0; \
        printf("\n========== UNITY TEST SUITE ==========\n\n"); \
    } while(0)

#define UNITY_END() \
    do { \
        printf("\n========== TEST RESULTS ==========\n"); \
        printf("Tests run: %d\n", unity_tests_run); \
        printf("Tests failed: %d\n", unity_tests_failed); \
        if (unity_tests_failed == 0) { \
            printf("\nALL TESTS PASSED!\n\n"); \
            return 0; \
        } else { \
            printf("\nSOME TESTS FAILED!\n\n"); \
            return 1; \
        } \
    } while(0)

#endif /* UNITY_H */

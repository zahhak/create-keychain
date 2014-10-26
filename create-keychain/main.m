//
//  main.m
//  create-keychain
//
//  Created by Ilian Iliev on 10/26/14.
//  Copyright (c) 2014 Ilian Iliev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "readline.h"
#import "security.h"

#include <Security/SecKeychain.h>

static int
do_create(const char *keychain, const char *password, Boolean do_prompt)
{
    SecKeychainRef keychainRef = NULL;
    OSStatus result;
    
    result = SecKeychainCreate(keychain, password ? strlen(password) : 0, password, do_prompt, NULL, &keychainRef);
    
    
    if (keychainRef)
        CFRelease(keychainRef);
    
    if (result)
        sec_error("SecKeychainCreate %s: %s", keychain, sec_errstr(result));
    
    return result;
}

int main(int argc, char * const *argv) {
    @autoreleasepool {
        int free_keychain = 0, zero_password = 0;
        char *password = NULL, *keychain = NULL;
        int ch, result = 0;
        Boolean do_prompt = FALSE;
        
        /* AG: getopts optstring name [args]
         AG: while loop calling getopt is used to extract password from cl from user
         password is the only option to keychain_create
         optstring  is  a  string  containing the legitimate option
         characters.  If such a character is followed by  a  colon,
         the  option  requires  an  argument,  so  getopt  places a
         pointer to the following text in the same argv-element, or
         the  text  of  the following argv-element, in optarg.
         */
        while ((ch = getopt(argc, argv, "hp:P")) != -1)
        {
            switch  (ch)
            {
                case 'p':
                    password = optarg;
                    break;
                case 'P':
                    do_prompt = TRUE;
                    break;
                case '?':
                default:
                    return 2; /* @@@ Return 2 triggers usage message. */
            }
        }
        /*
         AG:   The external variable optind is  the  index  of  the  next
         array  element  of argv[] to be processed; it communicates
         from one call of getopt() to the  next  which  element  to
         process.
         The variable optind is the index of the next element of the argv[] vector to 	be processed. It shall be initialized to 1 by the system, and getopt() shall 	update it when it finishes with each element of argv[]. When an element of argv[] 	contains multiple option characters, it is unspecified how getopt() determines 	which options have already been processed.
         
         */
        argc -= optind;
        argv += optind;
        
        
        if (argc > 0)
            keychain = *argv;
        else
        {
            fprintf(stderr, "keychain to create: ");
            keychain = readline(NULL, 0);
            if (!keychain)
            {
                result = -1;
                goto loser;
            }
            
            free_keychain = 1;
            if (*keychain == '\0')
                goto loser;
        }
        
        if (!password && !do_prompt)
        {
            int compare = 1;
            int tries;
            
            for (tries = 3; tries-- > 0;)
            {
                char *firstpass;
                
                password = getpass("password for new keychain: ");
                if (!password)
                {
                    result = -1;
                    goto loser;
                }
                
                firstpass = malloc(strlen(password) + 1);
                strcpy(firstpass, password);
                password = getpass("retype password for new keychain: ");
                compare = password ? strcmp(password, firstpass) : 1;
                memset(firstpass, 0, strlen(firstpass));
                free(firstpass);
                if (!password)
                {
                    result = -1;
                    goto loser;
                }
                
                if (compare)
                {
                    fprintf(stderr, "passwords don't match\n");
                    memset(password, 0, strlen(password));
                }
                else
                {
                    zero_password = 1;
                    break;
                }
            }
            
            if (compare)
            {
                result = 1;
                goto loser;
            }
        }
        
        do
        {
            result = do_create(keychain, password, do_prompt);
            if (zero_password)
                memset(password, 0, strlen(password));
            if (result)
                goto loser;
            
            argc--;
            argv++;
            if (!free_keychain)
                keychain = *argv;
        } while (argc > 0);
        
    loser:
        if (free_keychain)
            free(keychain);
        
        return result;
    }
}

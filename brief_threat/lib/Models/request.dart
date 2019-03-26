// request model class
class Request {
  String amount;
  String course;
  String customerName;
  int id;
  String receipt;
  String paymentMethod;
  DateTime resolvedAt;
  String submitter;
  DateTime submittedTime;

  Request(String amount, String course, String customerName, int id, String paymentMethod, int resolvedAt, String receipt, String submitter, int submittedTime) {
    this.amount = amount;
    this.course = course;
    this.customerName = customerName;
    this.id = id;
    this.receipt =receipt;
    this.paymentMethod =paymentMethod;
    // backend sends date as seconds since epoch, dart only handles milliseconds or microseconds, so we multiply by 1000 to make seconds into milliseconds
    this.resolvedAt = resolvedAt == null ? null : new DateTime.fromMillisecondsSinceEpoch(resolvedAt * 1000);
    this.submitter =submitter;
    this.submittedTime = new DateTime.fromMillisecondsSinceEpoch(submittedTime * 1000);
  }

  // get a request instance from json data
  factory Request.fromJson(Map<String, dynamic> parsedJson){
    return Request(parsedJson['amount'], parsedJson['course'], parsedJson['customer_name'], parsedJson['id'], parsedJson['payment_method'], parsedJson['resolved_at'], parsedJson['receipt'], parsedJson['submitter'], parsedJson['time']);
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? dateFrom(dynamic value) =>
    value is Timestamp ? value.toDate() : value as DateTime?;

class AppUser {
  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    this.studentNumber,
    this.photoUrl,
    this.createdAt,
    this.lastSeen,
    this.isActive = true,
  });
  final String uid, fullName, email;
  final String? studentNumber, photoUrl;
  final DateTime? createdAt, lastSeen;
  final bool isActive;
  factory AppUser.fromMap(String id, Map<String, dynamic> data) => AppUser(
    uid: id,
    fullName: data['fullName'] ?? '',
    email: data['email'] ?? '',
    studentNumber: data['studentNumber'],
    photoUrl: data['photoUrl'],
    createdAt: dateFrom(data['createdAt']),
    lastSeen: dateFrom(data['lastSeen']),
    isActive: data['isActive'] ?? true,
  );
}

class Group {
  const Group({
    required this.id,
    required this.name,
    required this.course,
    required this.leaderId,
    required this.code,
    required this.maxMembers,
    required this.joinType,
    this.description = '',
    this.courseworkTitle = '',
    this.deadline,
    this.repositoryUrl,
    this.repositoryName,
    this.isLocked = false,
    this.createdAt,
  });
  final String id,
      name,
      course,
      leaderId,
      code,
      description,
      courseworkTitle,
      joinType;
  final int maxMembers;
  final DateTime? deadline, createdAt;
  final String? repositoryUrl, repositoryName;
  final bool isLocked;
  factory Group.fromMap(String id, Map<String, dynamic> data) => Group(
    id: id,
    name: data['name'] ?? '',
    course: data['course'] ?? '',
    leaderId: data['leaderId'] ?? '',
    code: data['code'] ?? '',
    description: data['description'] ?? '',
    courseworkTitle: data['courseworkTitle'] ?? '',
    maxMembers: (data['maxMembers'] ?? 1) as int,
    joinType: data['joinType'] ?? 'open',
    deadline: dateFrom(data['deadline']),
    repositoryUrl: data['repositoryUrl'],
    repositoryName: data['repositoryName'],
    isLocked: data['isLocked'] ?? false,
    createdAt: dateFrom(data['createdAt']),
  );
}

class Project {
  const Project({
    required this.id,
    required this.groupId,
    required this.title,
    required this.createdBy,
    this.description = '',
    this.deadline,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });
  final String id, groupId, title, createdBy;
  final String description;
  final String status;
  final DateTime? deadline, createdAt, updatedAt;
  bool get isCompleted => status == 'completed';
  bool get isArchived => status == 'archived';
  factory Project.fromMap(String id, Map<String, dynamic> data) => Project(
    id: id,
    groupId: data['groupId'] ?? '',
    title: data['title'] ?? '',
    description: data['description'] ?? '',
    deadline: dateFrom(data['deadline']),
    status: data['status'] ?? 'active',
    createdBy: data['createdBy'] ?? '',
    createdAt: dateFrom(data['createdAt']),
    updatedAt: dateFrom(data['updatedAt']),
  );
}

class Membership {
  const Membership({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    required this.status,
    this.fullName = '',
    this.joinedAt,
  });
  final String id, groupId, userId, role, status, fullName;
  final DateTime? joinedAt;
  bool get isLeader => role == 'leader';
  bool get isActive => status == 'active';
  factory Membership.fromMap(String id, Map<String, dynamic> data) =>
      Membership(
        id: id,
        groupId: data['groupId'] ?? '',
        userId: data['userId'] ?? '',
        role: data['role'] ?? 'member',
        status: data['status'] ?? 'active',
        fullName: data['fullName'] ?? 'Member',
        joinedAt: dateFrom(data['joinedAt']),
      );
}

class GroupTask {
  const GroupTask({
    required this.id,
    required this.projectId,
    required this.groupId,
    required this.title,
    required this.status,
    required this.priority,
    required this.createdBy,
    this.description = '',
    this.assignedTo,
    this.assignedName = '',
    this.deadline,
    this.createdAt,
    this.completedAt,
  });
  final String id, projectId, groupId, title, status, priority, createdBy;
  final String description;
  final String? assignedTo;
  final String assignedName;
  final DateTime? deadline, createdAt, completedAt;
  bool get completed => status == 'completed';
  bool get isOverdue =>
      !completed && deadline != null && deadline!.isBefore(DateTime.now());
  factory GroupTask.fromMap(String id, Map<String, dynamic> data) => GroupTask(
    id: id,
    projectId: data['projectId'] ?? data['groupId'] ?? '',
    groupId: data['groupId'] ?? '',
    title: data['title'] ?? '',
    description: data['description'] ?? '',
    status: data['status'] ?? 'notStarted',
    priority: data['priority'] ?? 'medium',
    createdBy: data['createdBy'] ?? '',
    assignedTo: data['assignedTo'],
    assignedName: data['assignedName'] ?? '',
    createdAt: dateFrom(data['createdAt']),
    completedAt: dateFrom(data['completedAt']),
    deadline: dateFrom(data['deadline']),
  );
}

class GroupNote {
  const GroupNote({
    required this.id,
    required this.projectId,
    required this.groupId,
    required this.title,
    required this.content,
    required this.updatedBy,
    this.updatedAt,
    this.createdAt,
  });
  final String id, projectId, groupId, title, content, updatedBy;
  final DateTime? updatedAt, createdAt;
  factory GroupNote.fromMap(String id, Map<String, dynamic> data) => GroupNote(
    id: id,
    projectId: data['projectId'] ?? data['groupId'] ?? '',
    groupId: data['groupId'] ?? '',
    title: data['title'] ?? '',
    content: data['content'] ?? '',
    updatedBy: data['updatedBy'] ?? '',
    updatedAt: dateFrom(data['updatedAt']),
    createdAt: dateFrom(data['createdAt']),
  );
}

class WorkspaceFile {
  const WorkspaceFile({
    required this.id,
    required this.projectId,
    required this.groupId,
    required this.name,
    required this.storagePath,
    required this.downloadUrl,
    required this.category,
    required this.uploaderId,
    required this.size,
    this.createdAt,
    this.uploaderName = '',
  });
  final String id,
      projectId,
      groupId,
      name,
      storagePath,
      downloadUrl,
      category,
      uploaderId;
  final String uploaderName;
  final int size;
  final DateTime? createdAt;
  factory WorkspaceFile.fromMap(String id, Map<String, dynamic> data) =>
      WorkspaceFile(
        id: id,
        projectId: data['projectId'] ?? data['groupId'] ?? '',
        groupId: data['groupId'] ?? '',
        name: data['filename'] ?? '',
        storagePath: data['storagePath'] ?? '',
        downloadUrl: data['downloadUrl'] ?? '',
        category: data['category'] ?? 'other',
        uploaderId: data['uploaderId'] ?? '',
        uploaderName: data['uploaderName'] ?? '',
        size: (data['size'] ?? 0) as int,
        createdAt: dateFrom(data['createdAt']),
      );
}

class DiscussionPost {
  const DiscussionPost({
    required this.id,
    required this.projectId,
    required this.groupId,
    required this.authorId,
    required this.content,
    this.createdAt,
    this.updatedAt,
    this.authorName = '',
  });
  final String id, projectId, groupId, authorId, content;
  final String authorName;
  final DateTime? createdAt, updatedAt;
  factory DiscussionPost.fromMap(String id, Map<String, dynamic> data) =>
      DiscussionPost(
        id: id,
        projectId: data['projectId'] ?? data['groupId'] ?? '',
        groupId: data['groupId'] ?? '',
        authorId: data['authorId'] ?? '',
        content: data['content'] ?? '',
        authorName: data['authorName'] ?? '',
        createdAt: dateFrom(data['createdAt']),
        updatedAt: dateFrom(data['updatedAt']),
      );
}

class Comment {
  const Comment({
    required this.id,
    required this.postId,
    required this.groupId,
    required this.authorId,
    required this.content,
    this.createdAt,
    this.authorName = '',
  });
  final String id, postId, groupId, authorId, content;
  final String authorName;
  final DateTime? createdAt;
  factory Comment.fromMap(String id, Map<String, dynamic> data) => Comment(
    id: id,
    postId: data['postId'] ?? '',
    groupId: data['groupId'] ?? '',
    authorId: data['authorId'] ?? '',
    authorName: data['authorName'] ?? '',
    content: data['content'] ?? '',
    createdAt: dateFrom(data['createdAt']),
  );
}

class Announcement {
  const Announcement({
    required this.id,
    required this.groupId,
    required this.authorId,
    required this.content,
    this.createdAt,
    this.updatedAt,
    this.authorName = '',
  });
  final String id, groupId, authorId, content;
  final String authorName;
  final DateTime? createdAt, updatedAt;
  factory Announcement.fromMap(String id, Map<String, dynamic> data) =>
      Announcement(
        id: id,
        groupId: data['groupId'] ?? '',
        authorId: data['authorId'] ?? '',
        authorName: data['authorName'] ?? '',
        content: data['content'] ?? '',
        createdAt: dateFrom(data['createdAt']),
        updatedAt: dateFrom(data['updatedAt']),
      );
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.isRead,
    this.createdAt,
    this.type,
    this.relatedId,
  });
  final String id, userId, title, message;
  final bool isRead;
  final String? type, relatedId;
  final DateTime? createdAt;
  factory AppNotification.fromMap(String id, Map<String, dynamic> data) =>
      AppNotification(
        id: id,
        userId: data['userId'] ?? '',
        title: data['title'] ?? '',
        message: data['message'] ?? '',
        isRead: data['isRead'] ?? false,
        type: data['type'],
        relatedId: data['relatedId'],
        createdAt: dateFrom(data['createdAt']),
      );
}

class Submission {
  const Submission({
    required this.id,
    required this.projectId,
    required this.groupId,
    required this.submittedBy,
    required this.title,
    required this.description,
    required this.status,
    this.createdAt,
    this.submittedAt,
    this.fileUrl,
    this.repositoryUrl,
    this.authorName = '',
  });
  final String id, projectId, groupId, submittedBy, title, description, status;
  final String? fileUrl, repositoryUrl;
  final DateTime? createdAt, submittedAt;
  final String authorName;
  factory Submission.fromMap(String id, Map<String, dynamic> data) =>
      Submission(
        id: id,
        projectId: data['projectId'] ?? data['groupId'] ?? '',
        groupId: data['groupId'] ?? '',
        submittedBy: data['submittedBy'] ?? '',
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        status: data['status'] ?? 'draft',
        fileUrl: data['fileUrl'],
        repositoryUrl: data['repositoryUrl'],
        createdAt: dateFrom(data['createdAt']),
        submittedAt: dateFrom(data['submittedAt']),
        authorName: data['authorName'] ?? '',
      );
}

class ActivityLog {
  const ActivityLog({
    required this.id,
    required this.groupId,
    required this.actorId,
    required this.actionType,
    required this.description,
    this.createdAt,
    this.targetId,
    this.projectId,
    this.actorName = '',
  });
  final String id, groupId, actorId, actionType, description;
  final String? targetId, projectId;
  final String actorName;
  final DateTime? createdAt;
  factory ActivityLog.fromMap(String id, Map<String, dynamic> data) =>
      ActivityLog(
        id: id,
        groupId: data['groupId'] ?? '',
        actorId: data['actorId'] ?? '',
        actionType: data['actionType'] ?? '',
        description: data['description'] ?? '',
        targetId: data['targetId'],
        projectId: data['projectId'],
        actorName: data['actorName'] ?? '',
        createdAt: dateFrom(data['createdAt']),
      );
}

class NoteVersion {
  const NoteVersion({
    required this.id,
    required this.noteId,
    required this.content,
    required this.editedBy,
    this.editedByName = '',
    this.editedAt,
  });
  final String id, noteId, content, editedBy;
  final String editedByName;
  final DateTime? editedAt;
  factory NoteVersion.fromMap(String id, Map<String, dynamic> data) =>
      NoteVersion(
        id: id,
        noteId: data['noteId'] ?? '',
        content: data['content'] ?? '',
        editedBy: data['editedBy'] ?? '',
        editedByName: data['editedByName'] ?? '',
        editedAt: dateFrom(data['editedAt']),
      );
}

class JoinRequest {
  const JoinRequest({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.fullName,
    required this.email,
    this.status = 'pending',
    this.createdAt,
  });
  final String id, groupId, userId, fullName, email, status;
  final DateTime? createdAt;
  factory JoinRequest.fromMap(String id, Map<String, dynamic> data) =>
      JoinRequest(
        id: id,
        groupId: data['groupId'] ?? '',
        userId: data['userId'] ?? '',
        fullName: data['fullName'] ?? '',
        email: data['email'] ?? '',
        status: data['status'] ?? 'pending',
        createdAt: dateFrom(data['createdAt']),
      );
}

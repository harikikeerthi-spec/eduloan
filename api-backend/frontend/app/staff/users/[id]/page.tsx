"use client";

import { useState, useEffect, use } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useAuth } from "@/contexts/AuthContext";
import { adminApi, documentApi, staffProfileApi } from "@/lib/api";
import { format } from "date-fns";

export default function StaffUserDetailPage({ params }: { params: Promise<{ id: string }> }) {
    const router = useRouter();
    const { user } = useAuth();
    const { id: userId } = use(params);

    const [loading, setLoading] = useState(true);
    const [userData, setUserData] = useState<any>(null);
    const [userApplications, setUserApplications] = useState<any[]>([]);
    const [userDocuments, setUserDocuments] = useState<any[]>([]);
    const [staffProfile, setStaffProfile] = useState<any>(null);
    const [activeTab, setActiveTab] = useState<"profile" | "applications" | "documents">("profile");
    const [selectedApplication, setSelectedApplication] = useState<any>(null);
    const [expandedDoc, setExpandedDoc] = useState<string | null>(null);

    useEffect(() => {
        const fetchUserDetails = async () => {
            setLoading(true);
            try {
                // Fetch all users and find the one with matching ID
                const usersRes = await adminApi.getUsers() as any;
                const foundUser = usersRes.data?.find((u: any) => u.id === userId || u._id === userId);
                
                if (foundUser) {
                    setUserData(foundUser);

                    // Fetch user's applications
                    const appsRes = await adminApi.getApplications({}) as any;
                    const userApps = appsRes.data?.filter((app: any) => 
                        app.userId === userId || app.user_id === userId || app.applicantId === userId
                    ) || [];
                    setUserApplications(userApps);

                    // Fetch user's documents
                    try {
                        const docsRes = await documentApi.getUsersDocuments(userId) as any;
                        setUserDocuments(docsRes.data || []);
                    } catch (e) {
                        console.log("Could not fetch documents:", e);
                    }

                    // Fetch staff profile if exists
                    try {
                        const profilesRes = await staffProfileApi.list({ search: userId }) as any;
                        if (profilesRes.data && profilesRes.data.length > 0) {
                            setStaffProfile(profilesRes.data[0]);
                        }
                    } catch (e) {
                        console.log("Could not fetch staff profile:", e);
                    }
                }
            } catch (e) {
                console.error("Error fetching user details:", e);
            } finally {
                setLoading(false);
            }
        };

        fetchUserDetails();
    }, [userId]);

    const handleBack = () => {
        router.back();
    };

    if (loading) {
        return (
            <div className="min-h-screen bg-slate-50 font-sans text-slate-800 flex items-center justify-center">
                <div className="flex flex-col items-center gap-4">
                    <div className="w-10 h-10 border-4 border-slate-100 border-t-slate-900 rounded-full animate-spin" />
                    <p className="text-[11px] font-black tracking-widest text-slate-400 uppercase">Loading User Details...</p>
                </div>
            </div>
        );
    }

    if (!userData) {
        return (
            <div className="min-h-screen bg-slate-50 font-sans text-slate-800">
                <div className="max-w-6xl mx-auto px-6 py-12 text-center">
                    <p className="text-slate-500">User not found</p>
                    <button
                        onClick={handleBack}
                        className="mt-4 px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700"
                    >
                        Go Back
                    </button>
                </div>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-slate-50 font-sans text-slate-800">
            {/* Header */}
            <div className="bg-white border-b border-slate-200 sticky top-0 z-30 shadow-sm">
                <div className="max-w-6xl mx-auto px-6 py-4">
                    <button
                        onClick={handleBack}
                        className="flex items-center gap-2 text-sm font-medium text-slate-500 hover:text-slate-900 mb-4 transition-colors"
                    >
                        <span className="material-symbols-outlined text-[18px]">arrow_back</span>
                        Back to Dashboard
                    </button>

                    <div className="flex items-center gap-6">
                        <div className="w-16 h-16 rounded-full bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center text-white text-2xl font-black shadow-md border-4 border-white">
                            {(userData.firstName?.[0] || "U").toUpperCase()}{(userData.lastName?.[0] || "").toUpperCase()}
                        </div>
                        <div className="flex-1">
                            <h1 className="text-3xl font-black text-slate-900 tracking-tight">
                                {userData.firstName || "—"} {userData.lastName || ""}
                            </h1>
                            <div className="flex items-center gap-3 mt-2">
                                <span className="text-[12px] font-bold text-slate-500 uppercase tracking-wider">
                                    ID: {userId.slice(0, 8).toUpperCase()}
                                </span>
                                <span className={`px-2.5 py-1 rounded text-[10px] font-bold uppercase tracking-wide border ${
                                    userData.role?.includes("admin")
                                        ? "bg-slate-900 text-white border-slate-900"
                                        : "bg-indigo-50 text-indigo-700 border-indigo-200"
                                }`}>
                                    {userData.role?.replace("_", " ") || "USER"}
                                </span>
                                {userData.createdAt && (
                                    <span className="text-[11px] font-medium text-slate-500">
                                        Joined: {format(new Date(userData.createdAt), "MMM d, yyyy")}
                                    </span>
                                )}
                            </div>
                        </div>
                    </div>
                </div>

                {/* Tab Navigation */}
                <div className="max-w-6xl mx-auto px-6 flex gap-8 border-t border-slate-200">
                    {[
                        { id: "profile", label: "Profile Information", icon: "badge" },
                        { id: "applications", label: "Applications", icon: "description", count: userApplications.length },
                        { id: "documents", label: "Documents", icon: "folder", count: userDocuments.length },
                    ].map((tab) => (
                        <button
                            key={tab.id}
                            onClick={() => setActiveTab(tab.id as any)}
                            className={`py-4 font-bold text-[13px] uppercase tracking-wide border-b-2 flex items-center gap-2 transition-colors ${
                                activeTab === tab.id
                                    ? "border-indigo-600 text-indigo-600"
                                    : "border-transparent text-slate-500 hover:text-slate-700"
                            }`}
                        >
                            <span className="material-symbols-outlined text-[18px]">{tab.icon}</span>
                            {tab.label}
                            {tab.count !== undefined && (
                                <span className="ml-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-slate-100 text-slate-600">
                                    {tab.count}
                                </span>
                            )}
                        </button>
                    ))}
                </div>
            </div>

            {/* Main Content */}
            <div className="max-w-6xl mx-auto px-6 py-8">
                {/* Profile Tab */}
                {activeTab === "profile" && (
                    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                        {/* Personal Information */}
                        <div className="lg:col-span-2 bg-white rounded-lg border border-slate-200 p-8 shadow-sm">
                            <h2 className="text-lg font-bold text-slate-900 mb-6 flex items-center gap-2">
                                <span className="material-symbols-outlined">person</span>
                                Personal Information
                            </h2>
                            <div className="grid grid-cols-2 gap-6">
                                <div>
                                    <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-1">First Name</p>
                                    <p className="text-[14px] font-semibold text-slate-900">{userData.firstName || "—"}</p>
                                </div>
                                <div>
                                    <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-1">Last Name</p>
                                    <p className="text-[14px] font-semibold text-slate-900">{userData.lastName || "—"}</p>
                                </div>
                                <div>
                                    <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-1">Email</p>
                                    <p className="text-[14px] font-semibold text-slate-900 lowercase">{userData.email || "—"}</p>
                                </div>
                                <div>
                                    <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-1">Phone</p>
                                    <p className="text-[14px] font-semibold text-slate-900">{userData.mobile || userData.phone || "—"}</p>
                                </div>
                                <div>
                                    <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-1">Role</p>
                                    <p className="text-[14px] font-semibold text-slate-900 capitalize">{userData.role || "—"}</p>
                                </div>
                                <div>
                                    <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-1">Account Status</p>
                                    <span className="px-2.5 py-1 rounded text-[10px] font-bold uppercase tracking-wide bg-emerald-50 text-emerald-700 border border-emerald-200">
                                        Active
                                    </span>
                                </div>
                            </div>
                        </div>

                        {/* Quick Stats */}
                        <div className="space-y-4">
                            <div className="bg-white rounded-lg border border-slate-200 p-6 shadow-sm">
                                <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-2">Applications</p>
                                <p className="text-3xl font-black text-slate-900">{userApplications.length}</p>
                            </div>
                            <div className="bg-white rounded-lg border border-slate-200 p-6 shadow-sm">
                                <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-2">Documents</p>
                                <p className="text-3xl font-black text-slate-900">{userDocuments.length}</p>
                            </div>
                            <div className="bg-white rounded-lg border border-slate-200 p-6 shadow-sm">
                                <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-2">Member Since</p>
                                <p className="text-sm font-semibold text-slate-900">
                                    {userData.createdAt ? format(new Date(userData.createdAt), "MMM dd, yyyy") : "—"}
                                </p>
                            </div>
                        </div>
                    </div>
                )}

                {/* Applications Tab */}
                {activeTab === "applications" && (
                    <>
                        <div className="bg-white rounded-lg border border-slate-200 shadow-sm overflow-hidden">
                            {userApplications.length > 0 ? (
                                <div className="overflow-x-auto">
                                    <table className="w-full text-left">
                                        <thead className="bg-slate-50 border-b border-slate-200">
                                            <tr className="text-[11px] font-bold uppercase tracking-wider text-slate-500">
                                                <th className="px-6 py-3">Application ID</th>
                                                <th className="px-6 py-3">Bank</th>
                                                <th className="px-6 py-3">Loan Type</th>
                                                <th className="px-6 py-3">Status</th>
                                                <th className="px-6 py-3">Created Date</th>
                                                <th className="px-6 py-3 text-right">Actions</th>
                                            </tr>
                                        </thead>
                                        <tbody className="divide-y divide-slate-50">
                                            {userApplications.map((app, idx) => (
                                                <tr key={idx} className="hover:bg-slate-50 transition-colors">
                                                    <td className="px-6 py-4 text-[12px] font-bold text-slate-900">
                                                        #{app.applicationNumber?.toString().slice(0, 8) || app.id?.slice(0, 8).toUpperCase()}
                                                    </td>
                                                    <td className="px-6 py-4 text-[12px] font-semibold text-slate-700">{app.bank || "—"}</td>
                                                    <td className="px-6 py-4 text-[12px] font-semibold text-slate-700">{app.loanType || "—"}</td>
                                                    <td className="px-6 py-4">
                                                        <span className={`px-2.5 py-1 rounded text-[10px] font-bold uppercase tracking-wide border ${
                                                            app.status === "approved"
                                                                ? "bg-emerald-50 text-emerald-700 border-emerald-200"
                                                                : app.status === "rejected"
                                                                ? "bg-rose-50 text-rose-700 border-rose-200"
                                                                : app.status === "processing"
                                                                ? "bg-indigo-50 text-indigo-700 border-indigo-200"
                                                                : "bg-amber-50 text-amber-700 border-amber-200"
                                                        }`}>
                                                            {app.status || "Pending"}
                                                        </span>
                                                    </td>
                                                    <td className="px-6 py-4 text-[12px] font-semibold text-slate-500">
                                                        {app.createdAt ? format(new Date(app.createdAt), "MMM d, yyyy") : "—"}
                                                    </td>
                                                    <td className="px-6 py-4 text-right">
                                                        <button onClick={() => setSelectedApplication(app)} className="w-8 h-8 rounded bg-slate-100 hover:bg-indigo-50 text-slate-400 hover:text-indigo-600 flex items-center justify-center transition-all" title="View">
                                                            <span className="material-symbols-outlined text-[16px]">visibility</span>
                                                        </button>
                                                    </td>
                                                </tr>
                                            ))}
                                        </tbody>
                                    </table>
                                </div>
                            ) : (
                                <div className="py-16 text-center">
                                    <span className="material-symbols-outlined text-[48px] text-slate-300 mx-auto block mb-4">inbox</span>
                                    <p className="text-slate-500 font-semibold">No applications found for this user</p>
                                </div>
                            )}
                        </div>

                        {/* Application Details Panel */}
                        {selectedApplication && (
                            <div className="mt-8 bg-white rounded-lg border border-slate-200 shadow-sm p-8">
                                <div className="flex items-center justify-between mb-6">
                                    <h3 className="text-lg font-bold text-slate-900 flex items-center gap-2">
                                        <span className="material-symbols-outlined">description</span>
                                        Application Details
                                    </h3>
                                    <button
                                        onClick={() => setSelectedApplication(null)}
                                        className="w-8 h-8 rounded bg-slate-100 hover:bg-slate-200 text-slate-400 hover:text-slate-600 flex items-center justify-center transition-all"
                                        title="Close"
                                    >
                                        <span className="material-symbols-outlined text-[18px]">close</span>
                                    </button>
                                </div>

                                <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                                    {/* Left Column - Basic Info */}
                                    <div className="space-y-6">
                                        <div className="border-b border-slate-200 pb-6">
                                            <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-2">Application ID</p>
                                            <p className="text-[16px] font-black text-slate-900">
                                                #{selectedApplication.applicationNumber?.toString().slice(0, 8) || selectedApplication.id?.slice(0, 8).toUpperCase()}
                                            </p>
                                        </div>

                                        <div>
                                            <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-2">Bank/Lender</p>
                                            <p className="text-[14px] font-semibold text-slate-900">{selectedApplication.bank || "—"}</p>
                                        </div>

                                        <div>
                                            <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-2">Loan Type</p>
                                            <p className="text-[14px] font-semibold text-slate-900">{selectedApplication.loanType || "—"}</p>
                                        </div>

                                        <div>
                                            <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-2">Status</p>
                                            <span className={`inline-block px-3 py-1 rounded text-[11px] font-bold uppercase tracking-wide border ${
                                                selectedApplication.status === "approved"
                                                    ? "bg-emerald-50 text-emerald-700 border-emerald-200"
                                                    : selectedApplication.status === "rejected"
                                                    ? "bg-rose-50 text-rose-700 border-rose-200"
                                                    : selectedApplication.status === "processing"
                                                    ? "bg-indigo-50 text-indigo-700 border-indigo-200"
                                                    : "bg-amber-50 text-amber-700 border-amber-200"
                                            }`}>
                                                {selectedApplication.status || "Pending"}
                                            </span>
                                        </div>

                                        <div>
                                            <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-2">Created Date</p>
                                            <p className="text-[14px] font-semibold text-slate-900">
                                                {selectedApplication.createdAt ? format(new Date(selectedApplication.createdAt), "MMMM d, yyyy 'at' hh:mm a") : "—"}
                                            </p>
                                        </div>
                                    </div>

                                    {/* Right Column - Additional Details */}
                                    <div className="space-y-6">
                                        {selectedApplication.loanAmount && (
                                            <div>
                                                <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-2">Loan Amount</p>
                                                <p className="text-[16px] font-black text-slate-900">${selectedApplication.loanAmount.toLocaleString()}</p>
                                            </div>
                                        )}

                                        {selectedApplication.loanTenure && (
                                            <div>
                                                <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-2">Loan Tenure</p>
                                                <p className="text-[14px] font-semibold text-slate-900">{selectedApplication.loanTenure} months</p>
                                            </div>
                                        )}

                                        {selectedApplication.interestRate && (
                                            <div>
                                                <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-2">Interest Rate</p>
                                                <p className="text-[14px] font-semibold text-slate-900">{selectedApplication.interestRate}%</p>
                                            </div>
                                        )}

                                        {selectedApplication.updatedAt && (
                                            <div>
                                                <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-2">Last Updated</p>
                                                <p className="text-[14px] font-semibold text-slate-900">
                                                    {format(new Date(selectedApplication.updatedAt), "MMMM d, yyyy 'at' hh:mm a")}
                                                </p>
                                            </div>
                                        )}

                                        {selectedApplication.remarks && (
                                            <div>
                                                <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-2">Remarks</p>
                                                <p className="text-[13px] text-slate-700 bg-slate-50 border border-slate-200 rounded p-3">{selectedApplication.remarks}</p>
                                            </div>
                                        )}
                                    </div>
                                </div>

                                {/* Full Width Details */}
                                <div className="mt-8 pt-6 border-t border-slate-200 space-y-6">
                                    {selectedApplication.purpose && (
                                        <div>
                                            <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-2">Purpose</p>
                                            <p className="text-[13px] text-slate-700">{selectedApplication.purpose}</p>
                                        </div>
                                    )}

                                    {selectedApplication.documents && selectedApplication.documents.length > 0 && (
                                        <div>
                                            <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-3">Attached Documents</p>
                                            <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
                                                {selectedApplication.documents.map((doc: any, idx: number) => (
                                                    <div key={idx} className="flex items-center gap-2 p-2 bg-slate-50 border border-slate-200 rounded">
                                                        <span className="material-symbols-outlined text-[18px] text-slate-400">description</span>
                                                        <span className="text-[12px] font-semibold text-slate-700">{doc.docType || doc}</span>
                                                    </div>
                                                ))}
                                            </div>
                                        </div>
                                    )}
                                </div>
                            </div>
                        )}
                    </>
                )}

                {/* Documents Tab */}
                {activeTab === "documents" && (
                    <div className="bg-white rounded-lg border border-slate-200 shadow-sm overflow-hidden">
                        {userDocuments.length > 0 ? (
                            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 p-6">
                                {userDocuments.map((doc, idx) => {
                                    const docId = doc.id || doc._id || `${doc.docType || 'doc'}_${idx}`;
                                    const isExpanded = expandedDoc === docId;
                                    const ocrMeta = doc.verificationMetadata || doc.verification;
                                    const hasOcr = !!ocrMeta;
                                    const ocrResult = ocrMeta?.ocrResult || ocrMeta;
                                    const extractedFields = ocrResult?.extractedFields || ocrResult?.extracted_data;
                                    const confidence = ocrResult?.confidence !== undefined ? ocrResult.confidence : ocrMeta?.confidence;
                                    const ocrIssues = ocrResult?.ocr_issues || ocrMeta?.details?.ocr_issues || [];

                                    return (
                                        <div key={docId} className="border border-slate-200 rounded-lg p-4 hover:shadow-md transition-shadow bg-white flex flex-col justify-between">
                                            <div>
                                                <div className="flex items-start gap-3 mb-3">
                                                    <span className="material-symbols-outlined text-[24px] text-indigo-500">description</span>
                                                    <div className="flex-1 min-w-0">
                                                        <div className="flex items-center gap-1.5 flex-wrap">
                                                            <p className="text-[12px] font-bold text-slate-900 capitalize">{String(doc.docType || doc.type || "Document").replace(/_/g, ' ')}</p>
                                                            {hasOcr && (
                                                                <span className="px-1.5 py-0.5 rounded text-[8px] font-black uppercase tracking-wider bg-emerald-50 text-emerald-700 border border-emerald-200">
                                                                    AI Verified
                                                                </span>
                                                            )}
                                                        </div>
                                                        <p className="text-[10px] font-medium text-slate-500 truncate">{doc.fileName || doc.filePath?.split('/').pop() || "No filename"}</p>
                                                    </div>
                                                </div>
                                                {doc.uploadedAt && (
                                                    <p className="text-[10px] font-medium text-slate-400 mb-2">
                                                        Uploaded: {format(new Date(doc.uploadedAt), "MMM d, yyyy")}
                                                    </p>
                                                )}
                                                
                                                {hasOcr && isExpanded && (
                                                    <div className="mt-3 pt-3 border-t border-slate-100 space-y-3">
                                                        {confidence !== undefined && (
                                                            <div>
                                                                <div className="flex justify-between items-center text-[10px] font-bold text-slate-500 mb-1">
                                                                    <span>OCR Confidence</span>
                                                                    <span className="text-indigo-600">{Math.round((confidence > 1 ? confidence / 100 : confidence) * 100)}%</span>
                                                                </div>
                                                                <div className="w-full bg-slate-100 rounded-full h-1.5 overflow-hidden">
                                                                    <div 
                                                                        className={`h-1.5 rounded-full ${confidence > 0.8 || confidence > 80 ? 'bg-emerald-500' : confidence > 0.5 || confidence > 50 ? 'bg-amber-500' : 'bg-rose-500'}`} 
                                                                        style={{ width: `${Math.round((confidence > 1 ? confidence / 100 : confidence) * 100)}%` }} 
                                                                    />
                                                                </div>
                                                            </div>
                                                        )}

                                                        {extractedFields && Object.keys(extractedFields).length > 0 ? (
                                                            <div className="bg-slate-50 rounded-lg p-2.5 space-y-1.5">
                                                                <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1 flex items-center gap-1">
                                                                    <span className="material-symbols-outlined text-[12px]">list_alt</span>
                                                                    Extracted Fields
                                                                </p>
                                                                <div className="grid grid-cols-1 gap-1 text-[11px]">
                                                                    {Object.entries(extractedFields).map(([key, val]: any) => {
                                                                        if (val === null || val === undefined) return null;
                                                                        const valStr = typeof val === 'object' ? JSON.stringify(val) : String(val);
                                                                        if (!valStr.trim()) return null;
                                                                        return (
                                                                            <div key={key} className="flex justify-between items-start gap-2 border-b border-slate-100 pb-1 last:border-0 last:pb-0">
                                                                                <span className="text-slate-400 capitalize font-medium shrink-0">{key.replace(/_/g, ' ')}</span>
                                                                                <span className="text-slate-800 font-bold text-right break-all">{valStr}</span>
                                                                            </div>
                                                                        );
                                                                    })}
                                                                </div>
                                                            </div>
                                                        ) : (
                                                            <p className="text-[10px] italic text-slate-400">No fields extracted</p>
                                                        )}

                                                        {ocrIssues && ocrIssues.length > 0 && (
                                                            <div className="bg-rose-50 border border-rose-100 rounded-lg p-2.5 space-y-1">
                                                                <p className="text-[10px] font-bold text-rose-700 flex items-center gap-1">
                                                                    <span className="material-symbols-outlined text-[12px]">warning</span>
                                                                    OCR Warnings
                                                                </p>
                                                                <ul className="list-disc list-inside text-[10px] text-rose-600 font-medium space-y-0.5">
                                                                    {ocrIssues.map((issue: string, i: number) => (
                                                                        <li key={i}>{issue}</li>
                                                                    ))}
                                                                </ul>
                                                            </div>
                                                        )}
                                                    </div>
                                                )}
                                            </div>

                                            <div className="mt-3 pt-3 border-t border-slate-100 flex justify-between items-center gap-2">
                                                <button
                                                    onClick={() => {
                                                        const url = doc.filePath || doc.fileUrl || doc.url || `/api/documents/view/${userId}/${doc.docType}`;
                                                        window.open(url.startsWith('http') ? url : `/api/documents/view/${userId}/${doc.docType}`, '_blank');
                                                    }}
                                                    className="px-2.5 py-1.5 bg-slate-50 hover:bg-slate-100 text-slate-600 rounded text-[11px] font-bold transition-all flex items-center gap-1 border border-slate-200"
                                                >
                                                    <span className="material-symbols-outlined text-[14px]">visibility</span>
                                                    View
                                                </button>
                                                {hasOcr && (
                                                    <button
                                                        onClick={() => setExpandedDoc(isExpanded ? null : docId)}
                                                        className="px-2.5 py-1.5 text-indigo-600 hover:text-indigo-700 hover:bg-indigo-50/50 rounded text-[11px] font-bold transition-all flex items-center gap-1"
                                                    >
                                                        {isExpanded ? (
                                                            <>
                                                                <span>Hide OCR</span>
                                                                <span className="material-symbols-outlined text-[14px]">expand_less</span>
                                                            </>
                                                        ) : (
                                                            <>
                                                                <span>OCR Details</span>
                                                                <span className="material-symbols-outlined text-[14px]">expand_more</span>
                                                            </>
                                                        )}
                                                    </button>
                                                )}
                                            </div>
                                        </div>
                                    );
                                })}
                            </div>
                        ) : (
                            <div className="py-16 text-center">
                                <span className="material-symbols-outlined text-[48px] text-slate-300 mx-auto block mb-4">folder_off</span>
                                <p className="text-slate-500 font-semibold">No documents found for this user</p>
                            </div>
                        )}
                    </div>
                )}
            </div>
        </div>
    );
}

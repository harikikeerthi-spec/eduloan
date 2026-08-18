"use client";

import { useState, useEffect, use } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useAuth } from "@/contexts/AuthContext";
import { adminApi, documentApi } from "@/lib/api";
import { format } from "date-fns";

export default function StaffApplicationDetailPage({ params }: { params: Promise<{ id: string }> }) {
    const router = useRouter();
    const { user } = useAuth();
    const { id: applicationId } = use(params);

    const [loading, setLoading] = useState(true);
    const [application, setApplication] = useState<any>(null);
    const [userApplications, setUserApplications] = useState<any[]>([]);
    const [staffNotes, setStaffNotes] = useState<any[]>([]);
    const [newNote, setNewNote] = useState("");
    const [activeTab, setActiveTab] = useState<"details" | "history" | "documents" | "notes" | "verification">("details");
    const [userDocuments, setUserDocuments] = useState<any[]>([]);
    const [docsLoading, setDocsLoading] = useState(false);
    const [expandedDoc, setExpandedDoc] = useState<string | null>(null);

    useEffect(() => {
        const fetchApplicationDetails = async () => {
            setLoading(true);
            try {
                // Fetch all applications and find the one with matching ID
                const appsRes = await adminApi.getApplications({}) as any;
                const foundApp = appsRes.data?.find((a: any) => a.id === applicationId || a._id === applicationId);
                
                if (foundApp) {
                    setApplication(foundApp);

                    // Fetch all applications for this user
                    const userApps = appsRes.data?.filter((a: any) => 
                        (a.userId === foundApp.userId || a.applicantId === foundApp.applicantId || a.email === foundApp.email) &&
                        (a.id !== applicationId && a._id !== applicationId)
                    ) || [];
                    setUserApplications(userApps);

                    // Load staff notes (from localStorage for demo, would be from API in production)
                    const savedNotes = localStorage.getItem(`app_notes_${applicationId}`);
                    if (savedNotes) {
                        setStaffNotes(JSON.parse(savedNotes));
                    }

                    // Fetch applicant's actual documents
                    try {
                        const userId = foundApp.userId || foundApp.applicantId || foundApp.user_id;
                        if (userId) {
                            const docsRes = await documentApi.getUsersDocuments(userId) as any;
                            setUserDocuments(docsRes.data || []);
                        }
                    } catch (docErr) {
                        console.error("Could not fetch applicant documents:", docErr);
                    }
                }
            } catch (e) {
                console.error("Error fetching application details:", e);
            } finally {
                setLoading(false);
            }
        };

        fetchApplicationDetails();
    }, [applicationId]);

    const handleAddNote = () => {
        if (!newNote.trim()) return;
        
        const note = {
            id: Date.now().toString(),
            text: newNote,
            author: user?.firstName || "Staff",
            timestamp: new Date().toISOString(),
            type: "note"
        };
        
        const updatedNotes = [note, ...staffNotes];
        setStaffNotes(updatedNotes);
        localStorage.setItem(`app_notes_${applicationId}`, JSON.stringify(updatedNotes));
        setNewNote("");
    };

    const handlePullDocuments = () => {
        // This would trigger DigiLocker integration
        alert("Initiating document pull from DigiLocker for user: " + application?.email);
        // In production, would call: window.open(`/api/digilocker/authorize?userId=${application.userId}`, '_blank')
    };

    if (loading) {
        return (
            <div className="min-h-screen bg-slate-50 font-sans text-slate-800 flex items-center justify-center">
                <div className="flex flex-col items-center gap-4">
                    <div className="w-10 h-10 border-4 border-slate-100 border-t-slate-900 rounded-full animate-spin" />
                    <p className="text-[11px] font-black tracking-widest text-slate-400 uppercase">Loading Application...</p>
                </div>
            </div>
        );
    }

    if (!application) {
        return (
            <div className="min-h-screen bg-slate-50 font-sans text-slate-800">
                <div className="max-w-6xl mx-auto px-6 py-12 text-center">
                    <p className="text-slate-500">Application not found</p>
                    <button
                        onClick={() => router.back()}
                        className="mt-4 px-4 py-2 bg-emerald-600 text-white rounded hover:bg-emerald-700"
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
                <div className="max-w-7xl mx-auto px-6 py-4">
                    <button
                        onClick={() => router.back()}
                        className="flex items-center gap-2 text-sm font-medium text-slate-500 hover:text-slate-900 mb-4 transition-colors"
                    >
                        <span className="material-symbols-outlined text-[18px]">arrow_back</span>
                        Back to Pipeline
                    </button>

                    <div className="flex items-center gap-6 mb-6">
                        <div className="w-16 h-16 rounded-full bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center text-white text-2xl font-black shadow-md border-4 border-white">
                            {(application.firstName?.[0] || "U").toUpperCase()}{(application.lastName?.[0] || "").toUpperCase()}
                        </div>
                        <div className="flex-1">
                            <h1 className="text-3xl font-black text-slate-900 tracking-tight">
                                {application.firstName || "—"} {application.lastName || ""}
                            </h1>
                            <div className="flex items-center gap-3 mt-2">
                                <span className="text-[12px] font-bold text-slate-500 uppercase tracking-wider">
                                    App: #{application.applicationNumber?.toString().slice(0, 8) || "APP-0000"}
                                </span>
                                <span className={`px-3 py-1 rounded text-[10px] font-bold uppercase tracking-wide border ${
                                    application.status === "approved"
                                        ? "bg-emerald-50 text-emerald-700 border-emerald-200"
                                        : application.status === "rejected"
                                        ? "bg-rose-50 text-rose-700 border-rose-200"
                                        : application.status === "processing"
                                        ? "bg-indigo-50 text-indigo-700 border-indigo-200"
                                        : "bg-amber-50 text-amber-700 border-amber-200"
                                }`}>
                                    {application.status || "PENDING"}
                                </span>
                                <span className="text-[11px] font-bold text-slate-600 bg-slate-100 px-3 py-1 rounded">
                                    {application.bank}
                                </span>
                            </div>
                        </div>
                    </div>

                    {/* Quick Stats */}
                    <div className="grid grid-cols-4 gap-4 mb-6">
                        <div className="bg-gradient-to-br from-indigo-50 to-indigo-100 rounded-lg p-4 border border-indigo-200">
                            <p className="text-[10px] font-bold text-indigo-600 uppercase tracking-wider">Loan Amount</p>
                            <p className="text-2xl font-black text-indigo-900 mt-1">₹{Number(application.amount || 0).toLocaleString('en-IN')}</p>
                        </div>
                        <div className="bg-gradient-to-br from-emerald-50 to-emerald-100 rounded-lg p-4 border border-emerald-200">
                            <p className="text-[10px] font-bold text-emerald-600 uppercase tracking-wider">Tenure</p>
                            <p className="text-2xl font-black text-emerald-900 mt-1">{application.tenure || 0} Months</p>
                        </div>
                        <div className="bg-gradient-to-br from-amber-50 to-amber-100 rounded-lg p-4 border border-amber-200">
                            <p className="text-[10px] font-bold text-amber-600 uppercase tracking-wider">Interest Rate</p>
                            <p className="text-2xl font-black text-amber-900 mt-1">{application.interestRate || 0}%</p>
                        </div>
                        <div className="bg-gradient-to-br from-blue-50 to-blue-100 rounded-lg p-4 border border-blue-200">
                            <p className="text-[10px] font-bold text-blue-600 uppercase tracking-wider">Loan Type</p>
                            <p className="text-lg font-black text-blue-900 mt-1">{application.loanType || "—"}</p>
                        </div>
                    </div>
                </div>

                {/* Tab Navigation */}
                <div className="max-w-7xl mx-auto px-6 flex gap-8 border-t border-slate-200">
                    {[
                        { id: "details", label: "Application Details", icon: "description" },
                        { id: "history", label: "Previous Applications", icon: "history", count: userApplications.length },
                        { id: "documents", label: "Documents", icon: "folder", count: 0 },
                        { id: "verification", label: "Verification", icon: "verified_user" },
                        { id: "notes", label: "Internal Notes", icon: "note", count: staffNotes.length },
                    ].map((tab) => (
                        <button
                            key={tab.id}
                            onClick={() => setActiveTab(tab.id as any)}
                            className={`py-4 font-bold text-[13px] uppercase tracking-wide border-b-2 flex items-center gap-2 transition-colors ${
                                activeTab === tab.id
                                    ? "border-emerald-600 text-emerald-600"
                                    : "border-transparent text-slate-500 hover:text-slate-700"
                            }`}
                        >
                            <span className="material-symbols-outlined text-[18px]">{tab.icon}</span>
                            {tab.label}
                            {tab.count !== undefined && tab.count > 0 && (
                                <span className="ml-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-slate-100 text-slate-600">
                                    {tab.count}
                                </span>
                            )}
                        </button>
                    ))}
                </div>
            </div>

            {/* Main Content */}
            <div className="max-w-7xl mx-auto px-6 py-8">
                {/* Details Tab */}
                {activeTab === "details" && (
                    <div className="space-y-6">
                        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                            {/* Left Column - Applicant Info */}
                            <div className="lg:col-span-2 space-y-6">
                                <div className="bg-white rounded-lg border border-slate-200 p-8 shadow-sm">
                                    <h2 className="text-lg font-bold text-slate-900 mb-6 flex items-center gap-2">
                                        <span className="material-symbols-outlined">person</span>
                                        Applicant Information
                                    </h2>
                                    <div className="grid grid-cols-2 gap-6">
                                        <div>
                                            <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-1">First Name</p>
                                            <p className="text-[14px] font-semibold text-slate-900">{application.firstName || "—"}</p>
                                        </div>
                                        <div>
                                            <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-1">Last Name</p>
                                            <p className="text-[14px] font-semibold text-slate-900">{application.lastName || "—"}</p>
                                        </div>
                                        <div>
                                            <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-1">Email</p>
                                            <p className="text-[14px] font-semibold text-slate-900 lowercase">{application.email || "—"}</p>
                                        </div>
                                        <div>
                                            <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-1">Phone</p>
                                            <p className="text-[14px] font-semibold text-slate-900">{application.phone || "—"}</p>
                                        </div>
                                    </div>
                                </div>

                                <div className="bg-white rounded-lg border border-slate-200 p-8 shadow-sm">
                                    <h2 className="text-lg font-bold text-slate-900 mb-6 flex items-center gap-2">
                                        <span className="material-symbols-outlined">school</span>
                                        Loan Details
                                    </h2>
                                    <div className="grid grid-cols-2 gap-6">
                                        <div>
                                            <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-1">Loan Amount</p>
                                            <p className="text-[16px] font-black text-slate-900">₹{Number(application.amount || 0).toLocaleString('en-IN')}</p>
                                        </div>
                                        <div>
                                            <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-1">Tenure</p>
                                            <p className="text-[16px] font-black text-slate-900">{application.tenure || 0} Months</p>
                                        </div>
                                        <div>
                                            <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-1">Interest Rate</p>
                                            <p className="text-[16px] font-black text-slate-900">{application.interestRate || 0}%</p>
                                        </div>
                                        <div>
                                            <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-1">Loan Type</p>
                                            <p className="text-[14px] font-semibold text-slate-900">{application.loanType || "—"}</p>
                                        </div>
                                    </div>
                                </div>

                                {application.purpose && (
                                    <div className="bg-white rounded-lg border border-slate-200 p-8 shadow-sm">
                                        <h2 className="text-lg font-bold text-slate-900 mb-4 flex items-center gap-2">
                                            <span className="material-symbols-outlined">note</span>
                                            Loan Purpose
                                        </h2>
                                        <p className="text-[13px] text-slate-700 bg-slate-50 border border-slate-200 rounded p-4">{application.purpose}</p>
                                    </div>
                                )}

                                {application.createdAt && (
                                    <div className="bg-white rounded-lg border border-slate-200 p-8 shadow-sm">
                                        <h2 className="text-lg font-bold text-slate-900 mb-4">Timeline</h2>
                                        <div className="space-y-3">
                                            <div className="flex items-center gap-3">
                                                <span className="text-[11px] font-bold text-slate-400 uppercase">Applied</span>
                                                <p className="text-[13px] font-semibold text-slate-700">{format(new Date(application.createdAt), "MMMM d, yyyy 'at' hh:mm a")}</p>
                                            </div>
                                            {application.updatedAt && (
                                                <div className="flex items-center gap-3">
                                                    <span className="text-[11px] font-bold text-slate-400 uppercase">Last Updated</span>
                                                    <p className="text-[13px] font-semibold text-slate-700">{format(new Date(application.updatedAt), "MMMM d, yyyy 'at' hh:mm a")}</p>
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                )}
                            </div>

                            {/* Right Column - Staff View */}
                            <div className="space-y-6">
                                <div className="bg-white rounded-lg border border-slate-200 p-6 shadow-sm sticky top-32">
                                    <h3 className="text-lg font-bold text-slate-900 mb-6">Staff Resources</h3>
                                    
                                    <div className="space-y-3">
                                        <button
                                            onClick={handlePullDocuments}
                                            className="w-full px-4 py-2.5 bg-indigo-600 text-white text-[11px] font-bold rounded hover:bg-indigo-700 transition-all flex items-center justify-center gap-2"
                                        >
                                            <span className="material-symbols-outlined text-[16px]">cloud_download</span>
                                            Pull from DigiLocker
                                        </button>
                                        <button
                                            onClick={() => setActiveTab("verification")}
                                            className="w-full px-4 py-2.5 bg-slate-600 text-white text-[11px] font-bold rounded hover:bg-slate-700 transition-all flex items-center justify-center gap-2"
                                        >
                                            <span className="material-symbols-outlined text-[16px]">verified_user</span>
                                            View Documents
                                        </button>
                                        <button
                                            onClick={() => setActiveTab("notes")}
                                            className="w-full px-4 py-2.5 bg-slate-500 text-white text-[11px] font-bold rounded hover:bg-slate-600 transition-all flex items-center justify-center gap-2"
                                        >
                                            <span className="material-symbols-outlined text-[16px]">note</span>
                                            View Notes
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                )}

                {/* Previous Applications Tab */}
                {activeTab === "history" && (
                    <div className="bg-white rounded-lg border border-slate-200 shadow-sm overflow-hidden">
                        {userApplications.length > 0 ? (
                            <div className="overflow-x-auto">
                                <table className="w-full text-left">
                                    <thead className="bg-slate-50 border-b border-slate-200">
                                        <tr className="text-[11px] font-bold uppercase tracking-wider text-slate-500">
                                            <th className="px-6 py-3">Application ID</th>
                                            <th className="px-6 py-3">Bank</th>
                                            <th className="px-6 py-3">Loan Amount</th>
                                            <th className="px-6 py-3">Status</th>
                                            <th className="px-6 py-3">Applied Date</th>
                                        </tr>
                                    </thead>
                                    <tbody className="divide-y divide-slate-50">
                                        {userApplications.map((app, idx) => (
                                            <tr key={idx} className="hover:bg-slate-50 transition-colors">
                                                <td className="px-6 py-4 text-[12px] font-bold text-slate-900">
                                                    #{app.applicationNumber?.toString().slice(0, 8) || app.id?.slice(0, 8).toUpperCase()}
                                                </td>
                                                <td className="px-6 py-4 text-[12px] font-semibold text-slate-700">{app.bank || "—"}</td>
                                                <td className="px-6 py-4 text-[12px] font-bold text-slate-900">
                                                    ₹{Number(app.amount || 0).toLocaleString('en-IN')}
                                                </td>
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
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        ) : (
                            <div className="py-16 text-center">
                                <span className="material-symbols-outlined text-[48px] text-slate-300 mx-auto block mb-4">inbox</span>
                                <p className="text-slate-500 font-semibold">No previous applications for this user</p>
                            </div>
                        )}
                    </div>
                )}

                {/* Documents Tab */}
                {activeTab === "documents" && (
                    <div className="bg-white rounded-lg border border-slate-200 shadow-sm p-6">
                        <h2 className="text-lg font-bold text-slate-900 mb-4 flex items-center gap-2">
                            <span className="material-symbols-outlined text-indigo-500">folder_shared</span>
                            Applicant Documents Registry
                        </h2>
                        {userDocuments.length > 0 ? (
                            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                                {userDocuments.map((doc, idx) => {
                                    const docId = doc.id || doc._id || `doc_${idx}`;
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
                                                <div className="flex items-start gap-3 mb-2">
                                                    <span className="material-symbols-outlined text-slate-400 text-[24px]">description</span>
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
                                                                    Extracted Data
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
                                                        const userId = application.userId || application.applicantId || application.user_id;
                                                        const url = doc.filePath || doc.fileUrl || doc.url || `/api/documents/view/${userId}/${doc.docType}`;
                                                        window.open(url.startsWith('http') ? url : `/api/documents/view/${userId}/${doc.docType}`, '_blank');
                                                    }}
                                                    className="px-2.5 py-1.5 bg-slate-50 hover:bg-slate-100 text-slate-600 rounded text-[11px] font-bold transition-all flex items-center gap-1 border border-slate-200"
                                                >
                                                    <span className="material-symbols-outlined text-[14px]">visibility</span>
                                                    View Document
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
                            <div className="text-center py-12">
                                <span className="material-symbols-outlined text-[48px] text-slate-300 mx-auto block mb-4">folder_open</span>
                                <p className="text-slate-500 font-semibold">No uploaded documents found for this applicant.</p>
                            </div>
                        )}
                    </div>
                )}

                {/* Verification Tab */}
                {activeTab === "verification" && (
                    <div className="bg-white rounded-lg border border-slate-200 shadow-sm overflow-hidden">
                        <div className="p-8 space-y-6">
                            <h2 className="text-lg font-bold text-slate-900 mb-2">Applicant Verification Board</h2>
                            <p className="text-xs text-slate-500 border-b border-slate-100 pb-4">Audit AI OCR verification outputs and approve uploaded credentials.</p>
                            {userDocuments.length > 0 ? (
                                <div className="space-y-4">
                                    {userDocuments.map((doc, idx) => {
                                        const docId = doc.id || doc._id || `verify_${idx}`;
                                        const isExpanded = expandedDoc === docId;
                                        const ocrMeta = doc.verificationMetadata || doc.verification;
                                        const hasOcr = !!ocrMeta;
                                        const ocrResult = ocrMeta?.ocrResult || ocrMeta;
                                        const extractedFields = ocrResult?.extractedFields || ocrResult?.extracted_data;
                                        const confidence = ocrResult?.confidence !== undefined ? ocrResult.confidence : ocrMeta?.confidence;
                                        const ocrIssues = ocrResult?.ocr_issues || ocrMeta?.details?.ocr_issues || [];

                                        return (
                                            <div key={docId} className="p-4 border border-slate-200 rounded-lg hover:shadow-md transition-all bg-white">
                                                <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                                                    <div className="flex items-center gap-3">
                                                        <span className="material-symbols-outlined text-indigo-500 text-[28px]">verified_user</span>
                                                        <div>
                                                            <div className="flex items-center gap-2">
                                                                <p className="text-[13px] font-bold text-slate-900 capitalize">{String(doc.docType || doc.type || "Document").replace(/_/g, ' ')}</p>
                                                                <span className={`px-2 py-0.5 rounded text-[9px] font-black uppercase tracking-wider border ${
                                                                    hasOcr ? 'bg-emerald-50 text-emerald-700 border-emerald-200' : 'bg-amber-50 text-amber-700 border-amber-200'
                                                                }`}>
                                                                    {hasOcr ? 'AI Validated' : 'Pending Upload'}
                                                                </span>
                                                            </div>
                                                            <p className="text-[10px] text-slate-500 mt-0.5">Status: <span className="font-semibold text-indigo-600 uppercase">{doc.status || "uploaded"}</span></p>
                                                        </div>
                                                    </div>
                                                    <div className="flex items-center gap-2">
                                                        {hasOcr && (
                                                            <button 
                                                                onClick={() => setExpandedDoc(isExpanded ? null : docId)}
                                                                className="px-3 py-1.5 bg-slate-100 hover:bg-slate-200 text-slate-700 text-[11px] font-bold rounded flex items-center gap-1 transition-all"
                                                            >
                                                                <span className="material-symbols-outlined text-[14px]">query_stats</span>
                                                                {isExpanded ? 'Hide OCR' : 'Inspect OCR'}
                                                            </button>
                                                        )}
                                                        <button 
                                                            onClick={() => {
                                                                const userId = application.userId || application.applicantId || application.user_id;
                                                                const url = doc.filePath || doc.fileUrl || doc.url || `/api/documents/view/${userId}/${doc.docType}`;
                                                                window.open(url.startsWith('http') ? url : `/api/documents/view/${userId}/${doc.docType}`, '_blank');
                                                            }}
                                                            className="px-3 py-1.5 bg-indigo-50 hover:bg-indigo-100 text-indigo-600 text-[11px] font-bold rounded flex items-center gap-1 transition-all"
                                                        >
                                                            <span className="material-symbols-outlined text-[14px]">visibility</span>
                                                            View File
                                                        </button>
                                                    </div>
                                                </div>

                                                {hasOcr && isExpanded && (
                                                    <div className="mt-4 pt-4 border-t border-slate-150 grid grid-cols-1 md:grid-cols-2 gap-4">
                                                        {/* Left Column: Metrics & Warnings */}
                                                        <div className="space-y-3">
                                                            {confidence !== undefined && (
                                                                <div className="bg-slate-50 border border-slate-100 rounded-lg p-3">
                                                                    <div className="flex justify-between items-center text-[10px] font-bold text-slate-500 mb-1">
                                                                        <span>Confidence Score</span>
                                                                        <span className="text-indigo-600">{Math.round((confidence > 1 ? confidence / 100 : confidence) * 100)}%</span>
                                                                    </div>
                                                                    <div className="w-full bg-slate-200 rounded-full h-1.5 overflow-hidden">
                                                                        <div 
                                                                            className={`h-1.5 rounded-full ${confidence > 0.8 || confidence > 80 ? 'bg-emerald-500' : confidence > 0.5 || confidence > 50 ? 'bg-amber-500' : 'bg-rose-500'}`} 
                                                                            style={{ width: `${Math.round((confidence > 1 ? confidence / 100 : confidence) * 100)}%` }} 
                                                                        />
                                                                    </div>
                                                                </div>
                                                            )}

                                                            {ocrIssues && ocrIssues.length > 0 ? (
                                                                <div className="bg-rose-50 border border-rose-100 rounded-lg p-3">
                                                                    <p className="text-[10px] font-bold text-rose-700 flex items-center gap-1 mb-1">
                                                                        <span className="material-symbols-outlined text-[12px]">warning</span>
                                                                        Document Integrity Alerts
                                                                    </p>
                                                                    <ul className="list-disc list-inside text-[10px] text-rose-600 font-medium space-y-0.5">
                                                                        {ocrIssues.map((issue: string, i: number) => (
                                                                            <li key={i}>{issue}</li>
                                                                        ))}
                                                                    </ul>
                                                                </div>
                                                            ) : (
                                                                <div className="bg-emerald-50/50 border border-emerald-100 rounded-lg p-3">
                                                                    <p className="text-[10px] font-bold text-emerald-700 flex items-center gap-1">
                                                                        <span className="material-symbols-outlined text-[14px]">check_circle</span>
                                                                        No integrity alerts raised
                                                                    </p>
                                                                </div>
                                                            )}
                                                        </div>

                                                        {/* Right Column: Key-Values */}
                                                        <div>
                                                            {extractedFields && Object.keys(extractedFields).length > 0 ? (
                                                                <div className="bg-slate-50 rounded-lg p-3 space-y-1.5 border border-slate-100">
                                                                    <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1 flex items-center gap-1">
                                                                        <span className="material-symbols-outlined text-[12px]">list_alt</span>
                                                                        Extracted Fields
                                                                    </p>
                                                                    <div className="grid grid-cols-1 gap-1.5 text-[11px]">
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
                                                        </div>
                                                    </div>
                                                )}
                                            </div>
                                        );
                                    })}
                                </div>
                            ) : (
                                <div className="text-center py-12 bg-slate-50 border border-dashed border-slate-200 rounded-lg">
                                    <span className="material-symbols-outlined text-[48px] text-slate-300 mx-auto block mb-4">folder_off</span>
                                    <p className="text-slate-500 font-semibold">No uploaded documents available for verification.</p>
                                </div>
                            )}
                        </div>
                    </div>
                )}

                {/* Notes Tab */}
                {activeTab === "notes" && (
                    <div className="space-y-6">
                        <div className="bg-white rounded-lg border border-slate-200 p-8 shadow-sm">
                            <h2 className="text-lg font-bold text-slate-900 mb-6">Add Internal Note</h2>
                            <textarea
                                value={newNote}
                                onChange={(e) => setNewNote(e.target.value)}
                                placeholder="Add a note about this application..."
                                className="w-full p-4 bg-slate-50 border border-slate-200 rounded text-[13px] focus:outline-none focus:ring-2 focus:ring-emerald-500 min-h-[100px]"
                            />
                            <button
                                onClick={handleAddNote}
                                disabled={!newNote.trim()}
                                className="mt-4 px-6 py-2.5 bg-emerald-600 text-white text-[11px] font-bold rounded hover:bg-emerald-700 transition-all disabled:opacity-50"
                            >
                                Add Note
                            </button>
                        </div>

                        <div className="space-y-4">
                            <h3 className="text-lg font-bold text-slate-900">Staff Notes History</h3>
                            {staffNotes.length > 0 ? (
                                <div className="space-y-3">
                                    {staffNotes.map((note) => (
                                        <div key={note.id} className="bg-white rounded-lg border border-slate-200 p-6 shadow-sm">
                                            <div className="flex items-start justify-between mb-3">
                                                <div>
                                                    <p className="text-[12px] font-bold text-slate-900">{note.author}</p>
                                                    <p className="text-[10px] text-slate-500">{format(new Date(note.timestamp), "MMM d, yyyy 'at' hh:mm a")}</p>
                                                </div>
                                                {note.type === 'status_change' && (
                                                    <span className={`px-2.5 py-1 rounded text-[10px] font-bold uppercase ${
                                                        note.status === 'approved' ? 'bg-emerald-50 text-emerald-700' : 'bg-rose-50 text-rose-700'
                                                    }`}>
                                                        {note.status}
                                                    </span>
                                                )}
                                            </div>
                                            <p className="text-[13px] text-slate-700">{note.text}</p>
                                        </div>
                                    ))}
                                </div>
                            ) : (
                                <div className="text-center py-8 bg-slate-50 rounded-lg border border-slate-200">
                                    <p className="text-slate-500 text-[12px]">No notes yet</p>
                                </div>
                            )}
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
}

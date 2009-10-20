/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

// ScriptObjectQuarantine is used in JSC for wrapping DOM objects of the page
// before they are passed to Inspector's front-end. The wrapping prevents
// malicious scripts from gaining privileges. For V8, we are currently just
// passing the object itself, without any wrapping.

#ifndef ScriptObjectQuarantine_h
#define ScriptObjectQuarantine_h

#include "ScriptState.h"

namespace WebCore {

    class Database;
    class DOMWindow;
    class Node;
    class ScriptObject;
    class ScriptValue;
    class Storage;

    ScriptValue quarantineValue(ScriptState*, const ScriptValue&);

    bool getQuarantinedScriptObject(Database* database, ScriptObject& quarantinedObject);
    bool getQuarantinedScriptObject(Storage* storage, ScriptObject& quarantinedObject);
    bool getQuarantinedScriptObject(Node* node, ScriptObject& quarantinedObject);
    bool getQuarantinedScriptObject(DOMWindow* domWindow, ScriptObject& quarantinedObject);

}

#endif // ScriptObjectQuarantine_h
